# !/usr/bin/env python3

# seed for reproducibility
SEED = 42

# labels to predict
LABEL_COLS = [
    "label_ifc_entity",
    "label_predefined_type",
    "label_is_external",
    "label_load_bearing",
]

# config per base model: short name -> wandb key + checkpoint filename glob
MODEL_CONFIG = {
    "nn":      {"wandb_key": "plain_neural_network", "file_glob": "best_nn_model_*.pkl"},
    "xgboost": {"wandb_key": "xgboost", "file_glob": "best_xgboost_model_*.pkl"},
    "rf":      {"wandb_key": "random_forest", "file_glob": "best_rf_model_*.pkl"},
}

MODEL_NAMES = list(MODEL_CONFIG)

# data splits and their corresponding filenames (relative to DATA_DIR)
SPLITS = {
    "train": "dataset_train_rare_classes_removed.parquet",
    "val":  "dataset_validation_rare_classes_removed.parquet",
    "test": "dataset_test_rare_classes_removed.parquet",
}

# decision thresholds for each label (tuned on validation set)
CONFIDENCE_THRESHOLDS = {
    "label_ifc_entity":      0.85,
    "label_predefined_type": 0.50,
    "label_is_external":     0.75,
    "label_load_bearing":    0.75,
}

# classes the ensemble model was trained on
TRAINED_CLASSES = {
    "label_ifc_entity": [
        "IfcColumn", "IfcCovering", "IfcDoor", "IfcFurniture", "IfcPlate", "IfcRailing", "IfcRoof", "IfcSanitaryTerminal", "IfcSlab", "IfcSpace", "IfcStairFlight", "IfcWall", "IfcWindow",
    ],
    "label_predefined_type": [
        "BASESLAB", "COLUMN", "DOOR", "FLAT_ROOF", "FLOOR", "FLOORING", "GFA", "GUARDRAIL", "INTERNAL", "NOTDEFINED", "PARTITIONING", "PLUMBINGWALL", "SHEET", "SOLIDWALL", "TOILETPAN", "WASHHANDBASIN", "WINDOW",
    ],
    "label_is_external":  ["false", "true", "unknown"],
    "label_load_bearing": ["false", "true", "unknown"],
}