# !/usr/bin/env python3
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import pandas as pd

from _settings import LABEL_COLS, MODEL_NAMES

# constants for relative subprocess calls
CODE_DIR = Path(__file__).resolve().parent
RUNNER = CODE_DIR / "run_ensemble_model_prediction.py"
SPLIT_NAME = "demo"


class EnsemblePredictor:
    """Ensemble vote of nn + xgboost + rf. Each call spawns the three model subprocesses fresh."""

    def predict_proba(self, X, split_name = SPLIT_NAME, out_dir=None):
        """Averaged per-class probabilities per label. Returns dict {label: DataFrame (n_rows x n_classes_union)}."""

        # dump the input to a temp file and call the runner script for each model
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            input_path = tmp / "input.parquet"
            X.to_parquet(input_path)

            target = Path(out_dir) if out_dir is not None else tmp
            target.mkdir(parents=True, exist_ok=True)

            # launch all three models parallel to to prevent the libomp collision
            procs = [
                subprocess.Popen([
                    sys.executable, str(RUNNER), name,
                    "--input", str(input_path),
                    "--split-name", split_name,
                    "--out-dir", str(target),
                ])
                for name in MODEL_NAMES
            ]

            # check subprocesses and wait for them to finish
            for name, proc in zip(MODEL_NAMES, procs):
                if proc.wait() != 0:
                    raise RuntimeError(f"prediction subprocess for '{name}' failed: {proc.returncode}")

            # load per-label probabilities for each model
            probas = {model: {} for model in MODEL_NAMES}
            for model in MODEL_NAMES:
                for label in LABEL_COLS:
                    # use the split_name passed to this method (not the module-level SPLIT_NAME constant)
                    probas[model][label] = pd.read_parquet(target / f"proba_{model}_{label}_{split_name}.parquet")

        # align class sets across models and average
        out = {}
        for label in LABEL_COLS:
            per_model_dfs = [probas[model][label] for model in MODEL_NAMES]

            # each model may have seen a different subset of classes — align on the union
            all_classes = sorted({c for df in per_model_dfs for c in df.columns})
            aligned = [df.reindex(columns=all_classes, fill_value=0.0).values for df in per_model_dfs]

            out[label] = pd.DataFrame(np.mean(aligned, axis=0), columns=all_classes, index=X.index)
        return out

    def predict(self, X, split_name = SPLIT_NAME, out_dir=None):
        """Get predictions with highest averaged probability for each label (n_rows x n_labels)."""
        probas = self.predict_proba(X, split_name = split_name, out_dir=out_dir)

        # pick the class with the highest averaged probability for each label
        hard_preds = {}
        for label in LABEL_COLS:
            hard_preds[label] = probas[label].idxmax(axis=1).values

        return pd.DataFrame(hard_preds, index=X.index)
