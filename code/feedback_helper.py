# !/usr/bin/env python3
import json
import ifcopenshell
import ifcopenshell.util.placement
import numpy as np
import pandas as pd
from pathlib import Path

from bcf.v3.bcfxml import BcfXml # type: ignore
from bcf.v3.visinfo import VisualizationInfoHandler # type: ignore

# helper class to write a BCF report with one topic per misclassification bucket from an IFC model
class BCFCreator:
    """Builds a BCF where every (label, predicted_class, true_class) misclassification becomes one Issue group topic."""

    def __init__(self, ifc_path):
        self.ifc_path = Path(ifc_path)
        self.ifc_model = ifcopenshell.open(str(self.ifc_path))

        # camera positioned diagonally in front of the model centre for a generic overview viewpoint
        min_b, max_b = self._get_model_bounds()
        self.center = (min_b + max_b) / 2
        camera_distance = max(float(np.linalg.norm(max_b - min_b)) * 0.8, 10.0)
        self.camera_pos = self.center + np.array([camera_distance * 0.5, camera_distance * 0.5, camera_distance * 0.3])

    def create_bcf(self, predictions, label_cols, out_dir, pred_suffix="ensemble_pred", abstain_pred_values=("unknown",), abstain_true_values=(), trained_classes=None, save_json=True, author="eBKPh Classifier"):
        """Write a BCF topic for every (label, true class, predicted class) combination in the predictions DataFrame where the prediction is wrong."""

        # precompute sets for faster lookup in the loop below
        abstain_pred = set(abstain_pred_values or ())
        abstain_true = set(abstain_true_values or ())
        trained = {l: set(v) for l, v in (trained_classes or {}).items()}

        # bucket every misclassification into {(label, true_class, pred_class): [guid, ...]}
        groups = {}
        guids_with_abstain = set()
        guids_with_prediction = set()
        for _, row in predictions.iterrows():
            guid = row["guid"]
            for label in label_cols:
                true = row[f"{label}__true"]
                if true in abstain_true:
                    continue
                if label in trained and true not in trained[label]:
                    continue
                pred = row[f"{label}__{pred_suffix}"]
                if pred is None or (isinstance(pred, float) and pd.isna(pred)) or pred in abstain_pred:
                    guids_with_abstain.add(guid)
                    continue
                guids_with_prediction.add(guid)
                if true != pred:
                    groups.setdefault((label, true, pred), []).append(guid)

        # entirely unchecked elements never got a comparable prediction
        unchecked_guids = sorted(guids_with_abstain - guids_with_prediction)

        if not groups:
            print(f"No misclassifications found for: {self.ifc_path.name}")

        bcf = BcfXml.create_new(project_name=f"Misclassification feedback - {self.ifc_path.stem}")

        # sort largest buckets first to see the most impactful issues at the top of the topic list
        for (label, true, pred), guids in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            n = len(guids)
            title = f"{n} elements are '{true}', should be '{pred}' ({label})"
            description = (
                f"Label: {label}\n"
                f"Currently: {true}\n"
                f"Should be: {pred}\n"
                f"Affected count: {n}\n"
            )
            self._add_group_topic(bcf, guids, title, description, author, topic_type="Error", topic_status="Open")

        # final topic for elements that need manual review
        if unchecked_guids:
            n = len(unchecked_guids)
            title = f"{n} elements need manual review (no confident prediction)"
            description = (
                f"These elements were not predicted by the model."
                f"Please check these elements manually.\n"
                f"Affected count: {n}\n"
            )
            self._add_group_topic(bcf, unchecked_guids, title, description, author, topic_type="Info", topic_status="Open")

        out_dir = Path(out_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        bcf_path = out_dir / f"{self.ifc_path.stem}_misclassifications.bcf"
        bcf.save(str(bcf_path))
        bcf.close()

        # export grouped misclassifications as JSON if requested
        if save_json:
            json_data = [
                {
                    "label": label,
                    "true_class": true,
                    "predicted_class": pred,
                    "count": len(guids),
                    "element_guids": guids
                }
                for (label, true, pred), guids in sorted(groups.items(), key=lambda kv: -len(kv[1]))
            ]
            if unchecked_guids:
                json_data.append({
                    "label": "__unchecked__",
                    "true_class": None,
                    "predicted_class": None,
                    "count": len(unchecked_guids),
                    "element_guids": unchecked_guids,
                })
            json_path = out_dir / f"{self.ifc_path.stem}_misclassifications.json"

            with open(json_path, "w") as f:
                json.dump(json_data, f, indent=2)

            print(f"json created: {json_path}")

        print(f"bcf created: {bcf_path} ({len(groups)} issue groups, {sum(len(g) for g in groups.values())} element instances, {len(unchecked_guids)} unchecked)")
        return bcf_path

    def _add_group_topic(self, bcf, guids, title, description, author, topic_type, topic_status):
        # create topic for creating topics for Solibri
        topic = bcf.add_topic(title=title, description=description, author=author, topic_type=topic_type, topic_status=topic_status)

        # skip any guid that aren't in the model, so a single corrupt guid doesn't break the whole topic
        elements, valid_guids = [], []
        for guid in guids:
            try:
                elements.append(self.ifc_model.by_guid(guid))
                valid_guids.append(guid)
            except Exception:
                pass

        if not valid_guids:
            print(f"None of the {len(guids)} guids exist in {self.ifc_path.name}, skipping topic: {title}")
            vip = VisualizationInfoHandler.create_from_point_and_guids(self.camera_pos)
        else:
            # create one viewpoint per topic, with every affected element as a selected component
            vip = VisualizationInfoHandler.create_from_point_and_guids(self.camera_pos, *valid_guids)
            vip.set_selected_elements(elements)

        topic.add_visinfo_handler(vip)

    def _get_model_bounds(self):
        """Axis-aligned bounding box across all IfcProduct placements, falls back to a small default box if none are usable."""
        min_c, max_c = [float("inf")] * 3, [float("-inf")] * 3

        # get the global position and expand the bounding box
        for p in self.ifc_model.by_type("IfcProduct"):
            plc = getattr(p, "ObjectPlacement", None)
            if plc is None:
                continue
            try:
                pos = ifcopenshell.util.placement.get_local_placement(plc)[:3, 3]
            except Exception:
                continue
            for i in range(3):
                min_c[i] = min(min_c[i], pos[i])
                max_c[i] = max(max_c[i], pos[i])

        # fallback to a default box if no valid placements are found
        if min_c[0] == float("inf"):
            return np.array([-10, -10, 0]), np.array([10, 10, 3])
        
        return np.array(min_c), np.array(max_c)


# helper class to bucket per-label predictions into three categories (correct, misclassified, unchecked) and export them to Excel
class MisclassificationCounter:
    """Per-label/class breakdown of correct / misclassified / unchecked predictions and Excel export with one sheet per category."""

    def __init__(self, predictions, label_cols, pred_suffix="ensemble_pred", abstain_pred_values=("unknown",), abstain_true_values=(), trained_classes=None):
        self.predictions = predictions
        self.label_cols = label_cols
        self.pred_suffix = pred_suffix

        self.abstain_pred_values = set(abstain_pred_values or ())
        self.abstain_true_values = set(abstain_true_values or ())
        self.trained_classes = {l: set(v) for l, v in (trained_classes or {}).items()}

    def _in_scope_mask(self, label):
        # rows whose true class is in the trained set for this label
        trained = self.trained_classes.get(label)

        # if no whitelist given, every row is in scope
        if trained is None:
            return pd.Series(True, index=self.predictions.index)
        
        return self.predictions[f"{label}__true"].isin(trained)
    
    def _abstained_pred_mask(self, label):
        # prediction missing (NaN) or a sentinel like 'unknown' -> the model declined to commit
        pred = self.predictions[f"{label}__{self.pred_suffix}"]
        return pred.isna() | pred.isin(self.abstain_pred_values)

    def _abstained_true_mask(self, label):
        # ground truth itself is unknown -> nothing to score the prediction against
        return self.predictions[f"{label}__true"].isin(self.abstain_true_values)

    def _comparable_mask(self, label):
        # in scope AND both true and pred are concrete (neither abstained) -> we can evaluate true vs pred
        return self._in_scope_mask(label) & ~self._abstained_pred_mask(label) & ~self._abstained_true_mask(label)

    def _correct_mask(self, label):
        true_col, pred_col = f"{label}__true", f"{label}__{self.pred_suffix}"
        return (self.predictions[true_col] == self.predictions[pred_col]) & self._comparable_mask(label)

    def _wrong_mask(self, label):
        true_col, pred_col = f"{label}__true", f"{label}__{self.pred_suffix}"
        return (self.predictions[true_col] != self.predictions[pred_col]) & self._comparable_mask(label)

    def _unchecked_mask(self, label):
        # in scope but either the prediction or the truth is abstained -> not enough info to call right or wrong
        return self._in_scope_mask(label) & (self._abstained_pred_mask(label) | self._abstained_true_mask(label))

    def _row_categories(self):
        # per-row counts across all labels
        n_wrong = np.zeros(len(self.predictions), dtype=int)
        n_correct = np.zeros(len(self.predictions), dtype=int)
        n_unchecked = np.zeros(len(self.predictions), dtype=int)

        for label in self.label_cols:
            n_wrong += self._wrong_mask(label).values.astype(int)
            n_correct += self._correct_mask(label).values.astype(int)
            n_unchecked += self._unchecked_mask(label).values.astype(int)

        misclassified_mask = n_wrong > 0
        correct_mask = (n_wrong == 0) & (n_correct > 0)
        unchecked_mask = (n_wrong == 0) & (n_correct == 0) & (n_unchecked > 0)

        return misclassified_mask, correct_mask, unchecked_mask

    def count(self):
        """DataFrame with one row per (label, true class) seen in scope. Columns: label, class, n_correct, n_misclassified, n_unchecked, n_total, error_rate (= n_misclassified / (n_correct + n_misclassified)"""
        rows = []

        for label in self.label_cols:
            true_col = f"{label}__true"
            correct_counts = self.predictions.loc[self._correct_mask(label), true_col].value_counts()
            wrong_counts = self.predictions.loc[self._wrong_mask(label), true_col].value_counts()
            unchecked_counts = self.predictions.loc[self._unchecked_mask(label), true_col].value_counts()
            in_scope_counts = self.predictions.loc[self._in_scope_mask(label), true_col].value_counts()

            # iterate over every class that appeared in scope so always-correct and never-checked classes show up too
            for cls, n_total in in_scope_counts.sort_values(ascending=False).items():
                n_correct = int(correct_counts.get(cls, 0))
                n_wrong = int(wrong_counts.get(cls, 0))
                n_unchecked = int(unchecked_counts.get(cls, 0))
                n_checked = n_correct + n_wrong

                rows.append({
                    "label": label,
                    "class": cls,
                    "n_correct": n_correct,
                    "n_misclassified": n_wrong,
                    "n_unchecked": n_unchecked,
                    "n_total": int(n_total),
                    "error_rate": round(n_wrong / n_checked, 4) if n_checked else np.nan,
                })

        return pd.DataFrame(rows)

    def to_excel(self, path):
        """Write an Excel with four sheets: 'overview', 'misclassified', 'correct' and 'unchecked'. Rows whose every label is out of scope are dropped entirely."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)

        # column order for the per-row sheets: identifiers first, then per-label true/pred pairs
        detail_cols = [c for c in ("project_code", "guid") if c in self.predictions.columns]
        for label in self.label_cols:
            detail_cols += [f"{label}__true", f"{label}__{self.pred_suffix}"]

        # get the three buckets of rows and the overview table
        misclassified_mask, correct_mask, unchecked_mask = self._row_categories()
        overview = self.count()
        misclassified = self.predictions.loc[misclassified_mask, detail_cols].reset_index(drop=True)
        correct = self.predictions.loc[correct_mask, detail_cols].reset_index(drop=True)
        unchecked = self.predictions.loc[unchecked_mask, detail_cols].reset_index(drop=True)

        # write to Excel with one sheet per bucket
        with pd.ExcelWriter(path, engine="openpyxl") as writer:
            overview.to_excel(writer, sheet_name="overview", index=False)
            misclassified.to_excel(writer, sheet_name="misclassified", index=False)
            correct.to_excel(writer, sheet_name="correct", index=False)
            unchecked.to_excel(writer, sheet_name="unchecked", index=False)

        print(f"excel written: {path} (overview: {len(overview)}, misclassified: {len(misclassified)}, correct: {len(correct)}, unchecked: {len(unchecked)})")
        return path
