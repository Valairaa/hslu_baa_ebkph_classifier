# !/usr/bin/env python3
import sys
from pathlib import Path

import ifcopenshell
import numpy as np
import pandas as pd

# helpers
sys.path.insert(0, "../")

from _settings import LABEL_COLS, CONFIDENCE_THRESHOLDS, TRAINED_CLASSES
from dataloader import PROPERTY_MAPPING, _extract_from_model
from geometric_extraction_helper import (
    _get_settings, iter_elements_with_features,
    GENERAL_KEYS, AABB_KEYS, TFBB_KEYS, TOPO_KEYS, MATERIAL_KEYS, RAY_KEYS,
)
from ensemble_helper import EnsemblePredictor
from feedback_helper import BCFCreator, MisclassificationCounter


class DemoFeedbackGenerator:
    """Run soft-vote feedback generation for a single IFC model: extract features, predict with ensemble, generate BCF / Excel / JSON reports."""

    def __init__(self, ifc_path, out_dir="./feedback/", project_id = "TMP_PROJECT", save_bcf=True, save_excel=True, save_json=True, cache_file=True):
        self.ifc_path = Path(ifc_path)
        self.out_dir = Path(out_dir)
        self.project_id = project_id
        self.save_bcf = save_bcf
        self.save_excel = save_excel
        self.save_json = save_json
        self.cache_file = cache_file

        self.out_dir.mkdir(parents=True, exist_ok=True)

    def extract_features_and_labels(self):
        """Extract features (geometric, material, ray-cast) and ground-truth labels directly from IFC. Returns DataFrame with all elements."""
        # cache the extracted dataset next to the IFC because re-extraction is expensive
        cache_path = self.ifc_path.with_name(f"{self.ifc_path.stem}_extracted.parquet")

        if self.cache_file and cache_path.exists():
            df = pd.read_parquet(cache_path)
            print(f"loaded {len(df):,} elements from cache: {cache_path.name}")
        else:
            ifc_file = ifcopenshell.open(str(self.ifc_path))

            # extract main labels (ifc entity, predefined type) for all elements
            main_rows = []
            for product in ifc_file.by_type("IfcProduct"):
                predefined = getattr(product, "PredefinedType", None)
                main_rows.append({
                    "guid": product.GlobalId,
                    "label_ifc_entity": product.is_a(),
                    "label_predefined_type": str(predefined) if predefined is not None else None,
                })
            df_main = pd.DataFrame(main_rows)

            # extract additional labels like is_external and load_bearing directly from the property sets
            label_props = _extract_from_model(ifc_file, PROPERTY_MAPPING)
            df_labels = pd.DataFrame.from_dict(label_props, orient="index").reset_index().rename(columns={"index": "guid"}).fillna("unknown")

            # extract geometric / material / ray features per element
            feature_rows = {el.GlobalId: feats for el, feats in iter_elements_with_features(ifc_file, settings=_get_settings())}
            df_features = pd.DataFrame.from_dict(feature_rows, orient="index").reset_index().rename(columns={"index": "guid"})

            # combine everything into one wide DataFrame
            df = df_main.merge(df_labels, on="guid", how="left").merge(df_features, on="guid", how="inner")
            df["project_code"] = self.project_id

            if self.cache_file:
                df.to_parquet(cache_path, index=False)
                print(f"extracted {len(df):,} elements from {self.ifc_path.name} and cached to {cache_path.name}")
            else:
                print(f"extracted {len(df):,} elements from {self.ifc_path.name}")

        # apply the same preprocessing as in the training pipeline
        # 1. drop rows where geometric extraction failed (NaN in geom keys)
        # 2. fill NaN in ray-cast and material features with -1
        geom_keys = GENERAL_KEYS + AABB_KEYS + TFBB_KEYS + TOPO_KEYS
        n_before = len(df)
        df = df.dropna(subset=geom_keys).reset_index(drop=True)
        df[RAY_KEYS] = df[RAY_KEYS].fillna(-1)
        df[MATERIAL_KEYS] = df[MATERIAL_KEYS].fillna(-1)
        print(f"after preprocessing: {len(df):,} elements ({n_before - len(df)} dropped for NaN geometry)")

        return df

    def predict_soft_vote(self, df):
        """Soft-vote prediction with confidence thresholds. Returns predictions DataFrame."""
        # initialize the ensemble predictor
        predictor = EnsemblePredictor()
        probas = predictor.predict_proba(df)

        # get soft-vote with confidence threshold
        y_pred = {}
        for l in LABEL_COLS:
            p = probas[l]
            top_prob = p.max(axis=1)
            top_class = p.idxmax(axis=1)
            y_pred[l] = top_class.where(top_prob >= CONFIDENCE_THRESHOLDS[l]).values
        y_pred = pd.DataFrame(y_pred)

        # report how many predictions per label surpassed the threshold
        for l in LABEL_COLS:
            n_kept = int(pd.Series(y_pred[l]).notna().sum())
            print(f"{l}: kept {n_kept:,}/{len(y_pred):,} predictions (threshold = {CONFIDENCE_THRESHOLDS[l]})")

        # create predictions table for feedback helpers
        predictions = pd.DataFrame({"project_code": df["project_code"].values, "guid": df["guid"].values})

        for l in LABEL_COLS:
            predictions[f"{l}__true"] = df[l].values
            predictions[f"{l}__ensemble_pred"] = y_pred[l].values

        return predictions

    def generate_reports(self, predictions):
        """Generate BCF, Excel, and JSON feedback reports."""
        # write reports -> skip rows whose true class was never trained and rows where the soft-vote abstained
        if self.save_bcf or self.save_json:
            bcf_creator = BCFCreator(self.ifc_path)
            bcf_creator.create_bcf(predictions, LABEL_COLS, out_dir=self.out_dir, trained_classes=TRAINED_CLASSES)

        if self.save_excel:
            counter = MisclassificationCounter(predictions, LABEL_COLS, trained_classes=TRAINED_CLASSES)
            excel_path = self.out_dir / f"{self.ifc_path.stem}_misclassifications.xlsx"
            counter.to_excel(excel_path)
            overview = counter.count()
            print(f"overview shape: {overview.shape}")

    def run(self):
        """Execute full feedback generation pipeline: extract features, predict, generate reports."""
        print(f"using IFC: {self.ifc_path.relative_to(self.ifc_path.parent.parent.parent)}")

        df = self.extract_features_and_labels()
        predictions = self.predict_soft_vote(df)
        self.generate_reports(predictions)

        print(f"reports saved to: {self.out_dir}")
