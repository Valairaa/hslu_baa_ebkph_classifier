# !/usr/bin/env python3
import argparse
import random
import sys
from pathlib import Path

import numpy as np
import pandas as pd

from _settings import MODEL_CONFIG, SEED, SPLITS

# config
CODE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(CODE_DIR))

# constants for relative subprocess calls
DATA_DIR = CODE_DIR / "3_data_curation_enrichement" / "3_9_split dataset to datasets and remove rare classes"
MODELS_DIR = CODE_DIR / "4_modeling" / "4_5_hyperparameter_tuning" / "models"
BEST_RUNS_PATH = CODE_DIR / "5_evaluation" / "5_1_get_best_runs_wandb" / "best_by_model_type.json"
PREDS_DIR = CODE_DIR / "predictions"

def import_runtime(name):
    """Import the model-specific runtime first to keep libomp runnable on Apple Silicon."""
    if name == "xgboost":
        import xgboost # type: ignore
        print(f"{name}: {xgboost.__version__} imported first", file=sys.stderr, flush=True)
    elif name == "nn":
        import torch # type: ignore
        print(f"{name}: {torch.__version__} imported first", file=sys.stderr, flush=True)


def seed_everything(name):
    """Make inference deterministic by seeding python, numpy and (for nn) torch with the project-wide SEED."""
    random.seed(SEED)
    np.random.seed(SEED)
    if name == "nn":
        import torch # type: ignore
        torch.manual_seed(SEED)
        if torch.backends.mps.is_available():
            torch.mps.manual_seed(SEED)


def load_model(name):
    """Find and load the best checkpoint for `name`, move NN to MPS if available."""
    # load model and feature names only within calling the method
    from models_helper import find_best_model_path, load_feature_names, load_model_pickle

    # load the best model checkpoint
    model_path = find_best_model_path(name, MODELS_DIR)
    print(f"{name} - loading {model_path}", file=sys.stderr, flush=True)
    model = load_model_pickle(model_path)

    # move NN to MPS if available, else keep ond CPU
    if name == "nn":
        import torch # type: ignore

        target = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
        model.pipeline._device = target
        model.pipeline.nn_model = model.pipeline.nn_model.to(target)

        print(f"{name} - moved to {target}", file=sys.stderr, flush=True)

    feature_names = load_feature_names(name, BEST_RUNS_PATH)
    return model, feature_names


def predict_and_dump(model, feature_names, name, df, split_name, out_dir):
    # give overview of the data we're predicting on
    print(f"model {name} - {split_name}: {len(df):,} rows, features: {len(feature_names)}", file=sys.stderr, flush=True)

    # predict and dump probabilities + predictions for each label as parquet files
    model.dump_predictions(df[feature_names], out_dir, name, split_name)
    print(f"model {name} wrote {split_name} preds + probas", file=sys.stderr, flush=True)


def main():
    # parse args
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name", choices=list(MODEL_CONFIG))
    parser.add_argument("--out-dir", default=str(PREDS_DIR), help="Directory to dump preds + proba parquet files.")
    parser.add_argument("--input", default=None, help="Parquet file to predict on. If not given, predictions will be made for all val/test splits.")
    parser.add_argument("--split-name", default="demo", help="default: 'demo'")
    args = parser.parse_args()

    # import model-specific runtime first to prevent libomp collision on Apple Silicon
    import_runtime(args.name)
    seed_everything(args.name)
    model, feature_names = load_model(args.name)
    out_dir = Path(args.out_dir)

    # if input file is given, predict on it, else predict on all val/test splits
    if args.input:
        df = pd.read_parquet(args.input)
        predict_and_dump(model, feature_names, args.name, df, args.split_name, out_dir)
    else:
        for split, filename in SPLITS.items():
            if split == "train":
                continue # skip train split for prediction
            df = pd.read_parquet(DATA_DIR / filename)
            predict_and_dump(model, feature_names, args.name, df, split, out_dir)


if __name__ == "__main__":
    main()
