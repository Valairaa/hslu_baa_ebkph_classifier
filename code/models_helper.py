# !/usr/bin/env python3
import io
import json
import pickle
from itertools import combinations
from pathlib import Path

import pandas as pd
import numpy as np

from sklearn.base import clone
from sklearn.multioutput import MultiOutputClassifier
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score, confusion_matrix, matthews_corrcoef

from _settings import MODEL_CONFIG, SEED
from dataviz_helper import plot_learning_curves, plot_class_contribution_comparison
from ml_models import model_registry, StringToIntWrapper

# helper function to find and load the best model checkpoints
def find_best_model_path(model_name, models_dir):
    """Return the highest-scoring saved checkpoint for a model (score parsed from filename suffix)."""
    pattern = MODEL_CONFIG[model_name]["file_glob"]
    paths = list(Path(models_dir).glob(pattern))
    if not paths:
        raise FileNotFoundError(f"No model files matching {Path(models_dir) / pattern}")

    # pick the path with the highest score
    best_path = paths[0]
    best_score = float(best_path.stem.split("_")[-1])

    for path in paths[1:]:
        score = float(path.stem.split("_")[-1])
        if score > best_score:
            best_path, best_score = path, score

    return best_path

# helper functions to get feature names from the best run's config
def load_feature_names(model_name, best_runs_path):
    """Return the feature column names used by the best run of a model (from best_by_model_type.json)."""
    runs = json.loads(Path(best_runs_path).read_text(encoding="utf-8"))
    return runs[MODEL_CONFIG[model_name]["wandb_key"]]["oversampling"]["best_val_f1_macro"]["feature_names"]

# helper function to load a pickled model checkpoint, remapping torch tensors to CPU for portability across different devices
def load_model_pickle(path):
    """Unpickle a saved model, remapping any torch tensors to CPU so the file is portable across devices. By training a model with torch, it memorizes the device it was trained on."""
    import torch # type: ignore

    # helper function in method due to torch import
    def load_to_cpu(byte_data):
        return torch.load(io.BytesIO(byte_data), map_location="cpu", weights_only=False)

    # force torch's tensors temporarily to cpu and load pickle file
    original_loader = torch.storage._load_from_bytes
    torch.storage._load_from_bytes = load_to_cpu
    
    try:
        with open(path, "rb") as f:
            return pickle.load(f)
    finally:
        torch.storage._load_from_bytes = original_loader

# helper function to evaluate predictions with multiple metrics and return a DataFrame
def evaluate_predictions(y_true, y_pred, label_cols):
    """Per-label accuracy, precision, recall, weighted F1, macro F1 and MCC as a DataFrame."""
    rows = [
        {
            "label": col,
            "accuracy": round(accuracy_score(y_true[col], y_pred[:, i]), 4),
            "precision": round(precision_score(y_true[col], y_pred[:, i], average="weighted", zero_division=0), 4),
            "recall": round(recall_score(y_true[col], y_pred[:, i], average="weighted", zero_division=0), 4),
            "mcc": round(matthews_corrcoef(y_true[col], y_pred[:, i]), 4),
            "f1_weighted": round(f1_score(y_true[col], y_pred[:, i], average="weighted", zero_division=0), 4),
            "f1_macro": round(f1_score(y_true[col], y_pred[:, i], average="macro", zero_division=0), 4),
        }
        for i, col in enumerate(label_cols)
    ]
    df = pd.DataFrame(rows).set_index("label")
    df.loc["mean"] = df.mean().round(4)
    return df

# helper to build a wide misclassification table with one __<model>_pred column per model
def build_misclassification_table(y_true_df, preds, label_cols):
    """Per-label missclassification table with one column per model's predictions, plus guid and project_code for reference."""
    rows = {"project_code": y_true_df["project_code"].values, "guid": y_true_df["guid"].values}
    any_wrong = np.zeros(len(y_true_df), dtype=bool)

    for label in label_cols:
        true = y_true_df[label].values
        rows[f"{label}__true"] = true

        for model, model_preds in preds.items():
            pred = model_preds[label].values
            rows[f"{label}__{model}_pred"] = pred
            any_wrong |= true != pred

    return pd.DataFrame(rows), any_wrong

# helper to extract per-tree vote distributions from a multi-output RandomForestClassifier for one label
def rf_vote_distributions(rf_model, X_df, feature_names, label, label_cols):
    """Per-row vote-count Series across all trees of a multi-output RF for one label. Each Series is indexed by class name, sorted by vote count descending."""
    label_idx = label_cols.index(label)
    label_classes = rf_model.classes_[label_idx]
    votes_matrix = np.column_stack([tree.predict(X_df[feature_names].values)[:, label_idx] for tree in rf_model.estimators_]).astype(int)
    return [pd.Series(label_classes[votes_matrix[i]]).value_counts().sort_values(ascending=False) for i in range(len(X_df))]

# helper to print the per-tree RF vote distribution for every misclassified row of one target class
def analyze_rf_misses(rf_model, full_table, feature_names, label, target_class, label_cols):
    """Print the full per-tree RF vote distribution for every row where the true class is `target_class` but RF misclassified it."""
    misses = full_table[
        (full_table[f"{label}__true"] == target_class) &
        (full_table[f"{label}__rf_pred"] != target_class)
    ].reset_index(drop=True)

    print(f"Found {len(misses)} rows where RF misclassified true class '{target_class}' on {label}\n")
    if not len(misses):
        return []

    results = []
    for i, counts in enumerate(rf_vote_distributions(rf_model, misses, feature_names, label, label_cols)):
        print(f"[{i}] {misses['project_code'].iloc[i]} / {misses['guid'].iloc[i]}  (rf_pred = {misses[f'{label}__rf_pred'].iloc[i]})")
        print(f"Vote distribution across all {len(rf_model.estimators_)} trees:")
        print(counts.to_string())
        print()

        results.append({
            "project_code": misses["project_code"].iloc[i],
            "guid":         misses["guid"].iloc[i],
            "rf_pred":      misses[f"{label}__rf_pred"].iloc[i],
            "votes":        {k: int(v) for k, v in counts.items()},
        })

    return results

# helper to pick the per-label XGBoost head from a MultiOutputClassifier-wrapped pipeline
def xgb_booster_for_label(xgb_multi, label, label_cols):
    """Return (booster, label_encoder) for the requested per-label head of a multi-output XGBoost classifier."""
    wrapper = xgb_multi.estimators_[label_cols.index(label)]
    return wrapper.estimator.get_booster(), wrapper.le_

# helper to extract the top-n features by absolute contribution for one sample/class from an XGBoost contribs matrix
def top_feature_contributions(contribs, class_idx, feature_names, X_row, n=10):
    """Top-n features by absolute contribution for one sample and one class."""
    feat_contribs = contribs[class_idx, :-1]  # drop bias term
    order         = np.argsort(np.abs(feat_contribs))[::-1][:n]
    return pd.DataFrame({
        "feature":      [feature_names[k] for k in order],
        "value":        [float(X_row[k]) for k in order],
        "contribution": feat_contribs[order],
    })

# helper to print the top-n per-feature contributions for every XGBoost-misclassified row of one target class
def analyze_xgb_misses(xgb_multi, full_table, feature_names, label, target_class, label_cols, n=8):
    """Print per-row top-n feature contributions for every row where the true class is `target_class` but XGBoost misclassified it."""
    import xgboost as xgb # type: ignore

    head_booster, head_le = xgb_booster_for_label(xgb_multi, label, label_cols)

    misses = full_table[
        (full_table[f"{label}__true"] == target_class) &
        (full_table[f"{label}__xgboost_pred"] != target_class)
    ].reset_index(drop=True)

    X_xgb = misses[feature_names]
    dmat = xgb.DMatrix(X_xgb.values, feature_names=feature_names)
    contribs_all = head_booster.predict(dmat, pred_contribs=True)  # (n_rows, n_classes, n_features + 1)
    true_idx = list(head_le.classes_).index(target_class)

    results = []
    for i in range(len(misses)):
        contribs = contribs_all[i]
        wrong_class = misses[f"{label}__xgboost_pred"].iloc[i]
        wrong_idx = list(head_le.classes_).index(wrong_class)

        x_values = X_xgb.iloc[i].values
        top_wrong = top_feature_contributions(contribs, wrong_idx, feature_names, x_values, n=n)
        top_true = top_feature_contributions(contribs, true_idx, feature_names, x_values, n=n)
        margin = float(contribs[wrong_idx].sum() - contribs[true_idx].sum())

        print(f"[{i}] {misses['project_code'].iloc[i]} / {misses['guid'].iloc[i]}  (xgb_pred = {wrong_class})")
        print(f"\nTop features pushing logit of WRONG class '{wrong_class}':")
        print(top_wrong.to_string(index=False))
        print(f"\nTop features pushing logit of TRUE class '{target_class}':")
        print(top_true.to_string(index=False))
        print(f"Logit margin (wrong - true): {margin:+.4f}")
        print()

        results.append({
            "project_code": misses["project_code"].iloc[i],
            "guid": misses["guid"].iloc[i],
            "xgb_pred": wrong_class,
            "logit_margin": margin,
            "top_wrong": top_wrong.to_dict(orient="records"),
            "top_true": top_true.to_dict(orient="records"),
        })

    return results

# helper to aggregate XGBoost per-feature contributions across all misses of one target class and plot them
def plot_xgb_misses_contributions(xgb_multi, full_table, feature_names, label, target_class, label_cols, top_n=15, save=None, chapter=None):
    """Plot mean per-feature contribution towards the WRONG vs TRUE class across all XGBoost misses of `target_class`, via `plot_class_contribution_comparison`. The wrong class varies per row, so the mean is taken across each row's own wrong class."""
    import xgboost as xgb # type: ignore
    
    head_booster, head_le = xgb_booster_for_label(xgb_multi, label, label_cols)

    misses = full_table[
        (full_table[f"{label}__true"] == target_class) &
        (full_table[f"{label}__xgboost_pred"] != target_class)
    ].reset_index(drop=True)

    X_xgb = misses[feature_names]
    dmat = xgb.DMatrix(X_xgb.values, feature_names=feature_names)
    contribs_all = head_booster.predict(dmat, pred_contribs=True)  # (n_rows, n_classes, n_features + 1)

    true_idx = list(head_le.classes_).index(target_class)
    true_contribs_mean = contribs_all[:, true_idx, :-1].mean(axis=0)

    # average contribution towards each row's own wrong class
    wrong_contribs_sum = np.zeros(len(feature_names))
    for i in range(len(misses)):
        wrong_idx = list(head_le.classes_).index(misses[f"{label}__xgboost_pred"].iloc[i])
        wrong_contribs_sum += contribs_all[i, wrong_idx, :-1]
    wrong_contribs_mean = wrong_contribs_sum / len(misses)

    # rank features by the biggest gap between mean wrong and mean true contribution
    gap = np.abs(wrong_contribs_mean - true_contribs_mean)
    order = np.argsort(gap)[::-1][:top_n]
    features_ord = [feature_names[i] for i in order]

    plot_class_contribution_comparison(
        features = features_ord,
        contrib_wrong = wrong_contribs_mean[order],
        contrib_true = true_contribs_mean[order],
        wrong_label = "wrong (various)",
        true_label = target_class,
        title = f"XGBoost mean per-feature contribution — {len(misses)} misses of '{target_class}' on {label}",
        save = save,
        chapter = chapter,
    )

# helper function to compute confusion matrices for each label and return them as a dict of DataFrames
def confusion_matrices_for_predictions(y_true, y_pred, label_cols):
    """Confusion matrix per label as a dict of DataFrames (rows=true, cols=predicted)."""
    out = {}
    for i, col in enumerate(label_cols):
        classes = sorted(y_true[col].unique())
        cm = confusion_matrix(y_true[col], y_pred[:, i], labels=classes)
        df = pd.DataFrame(cm, index=classes, columns=classes)
        df.index.name = "true"
        df.columns.name = "predicted"
        out[col] = df
    return out

# helper function to compute soft-vote ensemble predictions and their confidence (max proba) for each label
def softvote_pred_and_confidence(probas, label_cols):
    """Returns (pred, conf) dicts where pred[label] is an array of class labels and conf[label] their max-proba."""
    pred = {l: probas[l].idxmax(axis=1).to_numpy() for l in label_cols}
    conf = {l: probas[l].values.max(axis=1) for l in label_cols}
    return pred, conf

# helper function to sweep confidence thresholds for one label and return coverage and accuracy at each threshold as a DataFrame
def sweep_thresholds(y_true, sv_pred, sv_conf, label_cols, thresholds):
    """Returns a DataFrame with columns: label, conf_threshold, coverage, accuracy, precision, f1_macro, mcc."""
    rows = []
    for label in label_cols:
        yt = y_true[label].to_numpy()
        yp = sv_pred[label]
        conf = sv_conf[label]

        for conf_threshold in thresholds:
            mask = conf >= conf_threshold
            n_covered = int(mask.sum())

            if n_covered == 0:
                rows.append({"label": label, "conf_threshold": round(float(conf_threshold), 2), "coverage": 0.0, "n_covered": 0, "accuracy": np.nan, "precision": np.nan, "f1_macro": np.nan, "mcc": np.nan})
                continue

            rows.append({
                "label": label,
                "conf_threshold": round(float(conf_threshold), 2),
                "coverage": round(n_covered / len(yt), 4),
                "n_covered": n_covered,
                "accuracy": round(accuracy_score(yt[mask], yp[mask]), 4),
                "precision": round(precision_score(yt[mask], yp[mask], average="weighted", zero_division=0), 4),
                "f1_macro": round(f1_score(yt[mask], yp[mask], average="macro", zero_division=0), 4),
                "mcc":      round(matthews_corrcoef(yt[mask], yp[mask]), 4),
            })

    return pd.DataFrame(rows)

# helper function to pick the best confidence threshold for each label at a minimum coverage requirement
def best_conf_threshold_at_min_coverage(thr_df, min_coverage, label_cols):
    """For each label, return the confidence threshold with the highest accuracy among those that meet the minimum coverage requirement."""
    out = []
    for label in label_cols:
        sub = thr_df[(thr_df["label"] == label) & (thr_df["coverage"] >= min_coverage)].dropna(subset=["accuracy"])
        
        if sub.empty:
            out.append({"label": label, "conf_threshold": np.nan, "coverage": np.nan, "accuracy": np.nan, "f1_macro": np.nan})
            continue

        row = sub.loc[sub["accuracy"].idxmax()]
        out.append({"label": label, "conf_threshold": row["conf_threshold"], "coverage": row["coverage"], "precision": row["precision"], "f1_macro": row["f1_macro"]})

    return pd.DataFrame(out).set_index("label")

# wrapper class to train and evaluate multi-output classification models using sklearn Pipelines or NNClassifier.
class ModelTrainer:
    """Wraps a sklearn Pipeline or NNClassifier for multi-output classification."""

    def __init__(self, model, label_cols=None, **model_kwargs):
        self._is_nn = False

        if isinstance(model, str):
            if model not in model_registry:
                raise ValueError(f"Unknown model '{model}'. Available: {list(model_registry.keys())}")
            self.pipeline = model_registry[model](**model_kwargs)
            self.label_cols = label_cols
        else:
            self.pipeline = model
            self._is_nn = hasattr(model, "nn_model")
            self.label_cols = model.label_cols if self._is_nn else label_cols

    def fit(self, X_train, y_train, epochs=50, batch_size=64, lr=1e-3, device=None, X_val=None, y_val=None, on_epoch_end=None):
        if self._is_nn:
            self.pipeline.fit(X_train, y_train, epochs=epochs, batch_size=batch_size, lr=lr, device=device, X_val=X_val, y_val=y_val, on_epoch_end=on_epoch_end)
        else:
            self.pipeline.fit(X_train, y_train)
        return self

    def predict(self, X):
        return self.pipeline.predict(X)

    def predict_proba(self, X):
        """List of per-label probability arrays, one np.ndarray (n_rows x n_classes) per label in the column order given by `classes_per_label`."""
        return list(self.pipeline.predict_proba(X))

    @property
    def classes_per_label(self):
        """List of class arrays, one per label, matching the column order of predict_proba's output."""
        # possability 1: get classes from label encoders if it's a NN
        if hasattr(self.pipeline, "nn_model"):
            return [le.classes_ for le in self.pipeline._label_encoders]
        
        final = self.pipeline.named_steps["model"]
        # possability 2: if it's a MultiOutputClassifier, get classes on each sub-estimator
        if isinstance(final, MultiOutputClassifier):
            return [est.classes_ for est in final.estimators_]

        # possability 3: it is already a native multi-output model and returns a list of arrays
        return list(final.classes_)

    def dump_predictions(self, X, output_dir, name, split):
        """Predict on X and dump hard predictions plus per-class probabilities to output_dir as parquet."""
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)

        # save one file, one column per output label
        hard_preds_df = pd.DataFrame(self.predict(X), columns=self.label_cols)
        hard_preds_df.to_parquet(output_dir / f"preds_{name}_{split}.parquet")

        # save per-class probabilities — one file per output label
        probas_per_label = self.predict_proba(X)
        for label, proba, classes in zip(self.label_cols, probas_per_label, self.classes_per_label):
            class_names = [str(c) for c in classes]
            proba_df = pd.DataFrame(proba, columns=class_names)
            proba_df.to_parquet(output_dir / f"proba_{name}_{label}_{split}.parquet")

    def evaluate(self, X, y):
        """Returns per-label accuracy, precision, recall, weighted F1, macro F1 and MCC as a DataFrame."""
        return evaluate_predictions(y, self.predict(X), self.label_cols)

    def confusion_matrices(self, X, y):
        """Returns a confusion matrix per label as a dict of DataFrames."""
        return confusion_matrices_for_predictions(y, self.predict(X), self.label_cols)

    def feature_importances(self, feature_keys):
        """Returns feature importances for tree-based models, averaged across labels for MultiOutputClassifier."""
        if self._is_nn:
            raise NotImplementedError("not supported for neural network models.")
        model_step = self.pipeline.named_steps.get("model")

        if hasattr(model_step, "feature_importances_"):
            # get direct access if available -> RandomForestClassifier
            importances = model_step.feature_importances_
        elif hasattr(model_step, "estimators_"):
            # otherwise use MultiOutputClassifier -> XGBoost
            per_label = []
            for est in model_step.estimators_:
                inner = est.estimator if isinstance(est, StringToIntWrapper) else est
                if not hasattr(inner, "feature_importances_"):
                    raise ValueError(f"Estimator {type(inner).__name__} does not expose feature_importances_.")
                per_label.append(inner.feature_importances_)
            importances = np.mean(per_label, axis=0)
        else:
            raise ValueError("The pipeline's model step does not expose feature_importances_.")

        return (
            pd.DataFrame({"feature": feature_keys, "importance": importances})
            .sort_values("importance", ascending=False)
            .reset_index(drop=True)
        )

    def compare_training_sets(self, X_train, y_train, X_train_over, y_train_over, X_val, y_val):
        """Trains on regular and oversampled sets and return mcc and f1_macro for train and val sets as a DataFrame."""
        if self._is_nn:
            raise NotImplementedError("not supported for neural network models.")
        # define scenarios and metrics to compute
        scenarios = [("reg", X_train, y_train), ("over", X_train_over, y_train_over)]
        rows = {col: {} for col in self.label_cols}

        # train and evaluate each scenario
        for tag, X_tr, y_tr in scenarios:
            pipe = clone(self.pipeline)
            pipe.fit(X_tr, y_tr)

            for split, X_ev, y_ev in [("train", X_tr, y_tr), ("val", X_val, y_val)]:
                y_pred = pipe.predict(X_ev)
                for i, col in enumerate(self.label_cols):
                    # compute and store MCC and F1-Macro for this label and scenario
                    rows[col][f"{split}_{tag}_mcc"]      = round(matthews_corrcoef(y_ev[col], y_pred[:, i]), 4)
                    rows[col][f"{split}_{tag}_f1_macro"] = round(f1_score(y_ev[col], y_pred[:, i], average="macro", zero_division=0), 4)

        # convert the nested dict to a DataFrame, compute mean across labels and return
        df = pd.DataFrame(rows).T
        df.index.name = "label"
        df.loc["mean"] = df.mean().round(4)
        return df


# helper to train one model and return label-averaged train/val metrics as a flat dict for JSON export
def collect_model_metrics(model_name, label_cols, X_train, y_train, X_val, y_val, display_name=None):
    """Train a single model and return a flat dict with mean (across labels) train/val MCC + F1-macro plus val precision/accuracy."""
    trainer = ModelTrainer(model_name, label_cols)
    trainer.fit(X_train, y_train)

    train_mean = evaluate_predictions(y_train, trainer.predict(X_train), label_cols).loc["mean"]
    val_mean = evaluate_predictions(y_val, trainer.predict(X_val), label_cols).loc["mean"]

    return {
        "model": display_name or model_name,
        "train_mcc": float(train_mean["mcc"]),
        "train_f1_macro": float(train_mean["f1_macro"]),
        "val_mcc": float(val_mean["mcc"]),
        "val_f1_macro": float(val_mean["f1_macro"]),
        "val_precision": float(val_mean["precision"]),
        "val_accuracy": float(val_mean["accuracy"]),
    }


# helper class to evaluate all combinations of feature groups using a specified model
class FeatureGroupEvaluator:
    """Evaluates all combinations of feature groups using a given model."""

    def __init__(self, feature_groups, label_cols):
        self.feature_groups = feature_groups
        self.label_cols = label_cols

    def evaluate(self, X_train, y_train, X_test, y_test, model_fn=None):
        """Trains and evaluates all feature group combinations. Returns a DataFrame sorted by mean macro F1."""
        #  default to random forest if no model function is provided
        if model_fn is None:
            model_fn = "random_forest"

        # generate all combinations of feature group names
        group_names = list(self.feature_groups.keys())
        combos = [
            combo
            for r in range(1, len(group_names) + 1)
            for combo in combinations(group_names, r)
        ]

        # train and evaluate a model for each combination, collect results in a list of dicts
        rows = []
        for combo in combos:
            cols = [c for name in combo for c in self.feature_groups[name]]
            label = "+".join(combo)

            # train and evaluate the model on this feature subset
            trainer = ModelTrainer(model_fn, self.label_cols)
            trainer.fit(X_train[cols], y_train)

            # predict on the test set and compute per-label F1 macro scores
            y_pred = trainer.predict(X_test[cols])
            row = {"features": label, "n_features": len(cols)}

            # compute macro F1-Score for each label and store it in the row dict
            for i, col in enumerate(self.label_cols):
                row[col] = round(f1_score(y_test[col], y_pred[:, i], average="macro", zero_division=0), 3)
            rows.append(row)

        df = pd.DataFrame(rows).set_index("features")
        df["mean_f1_macro"] = df[self.label_cols].mean(axis=1).round(3)
        return df.sort_values("mean_f1_macro", ascending=False)

# helper function to plot learning curves for a specific class label as the number of training samples from that class increases.
def per_class_learning_curve(X, y, model, class_labels, label_name="", sample_sizes=None, X_val=None, y_val=None, threshold=None, save=None, chapter=None):
    """For each class in class_labels, trains with increasing samples of that class and measures its F1-Score on the validation set. All classes are shown as separate traces in a single plot. Returns a dict mapping each class label to (sizes, scores)."""
    # check that validation data is provided
    if X_val is None or y_val is None:
        raise ValueError("X_val and y_val must be provided.")

    # if sample sizes are not provided, use a default range
    if sample_sizes is None:
        sample_sizes = [1, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500]

    results = {}
    rng = np.random.default_rng(SEED)

    # for each class label, train with increasing samples of that class and evaluate on validation set
    for class_label in class_labels:
        scores = []
        for n in sample_sizes:
            target_idx = np.where(y == class_label)[0]

            # if there are not enough samples of this class, stop increasing sample size
            if len(target_idx) < n:
                break

            # randomly sample n instances of the target class and combine with all other classes
            sampled = rng.choice(target_idx, n, replace=False)
            other_idx = np.where(y != class_label)[0]
            idx = np.concatenate([sampled, other_idx])

            X_sub, y_sub = X[idx], y[idx]

            # fit the model on this subset and evaluate on the validation set
            model.fit(X_sub, y_sub)
            y_pred = model.predict(X_val)

            # compute macro F1-Score for this class label and store it
            score = f1_score(y_val, y_pred,
                             labels=[class_label], average='macro',
                             zero_division=0)
            scores.append(score)

        # only keep the sample sizes for which we have scores (in case we ran out of samples for this class)
        sizes = sample_sizes[:len(scores)]
        results[class_label] = (sizes, scores)

    plot_learning_curves(results, label_name=label_name, x_max=max(sample_sizes), legend_rows=4, threshold=threshold, save=save, chapter=chapter)

    return results