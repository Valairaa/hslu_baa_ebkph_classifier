# imports
import fnmatch
from pathlib import Path

import ifcopenshell
import ifcopenshell.util.element
import pandas as pd
import numpy as np
import re

from iterstrat.ml_stratifiers import MultilabelStratifiedShuffleSplit # type: ignore
from datasets import Dataset, DatasetDict # type: ignore
from imblearn.over_sampling import RandomOverSampler # type: ignore

from _settings import SEED


# mapping for extracting labels for eBKPh classification (pset_pattern, property_name, column_name)
PROPERTY_MAPPING = [
    # Lage (aussen / innen)
    ("Pset_*Common", "IsExternal", "label_is_external"),
    # Tragend / nicht tragend
    ("*Common", "LoadBearing", "label_load_bearing"),
    # UnterTerrain
    ("Eigenschaften_Schweiz_Allgemein", "Unter Terrain", "label_unter_terrain"),
    # Konstruktionsergänzung
    ("Eigenschaften_Schweiz_Allgemein", "Konstruktionsergänzung", "label_konstruktionsergaenzung"),
    # Deckbelag
    ("Eigenschaften_Schweiz_*", "Deckbelag", "label_deckbelag"),
    ("Eigenschaften_Schweiz_*", "Bekleidung", "label_bekleidung"),
    # Aussenliegendes Bauteil
    ("Eigenschaften_Schweiz_*", "Aussenliegendes Bauteil",  "label_aussenliegendes_bauteil"),
    # Erdverbunden
    ("Eigenschaften_Schweiz_Allgemein", "Erdverbunden", "label_erdverbunden"),
    # Unterkonstruktion (Boden, Decke, Wand)
    ("Eigenschaften_Schweiz_*",         "Unterkonstruktion", "label_unterkonstruktion"),
    # Verdunkelung, Schutzschicht, Sonnenschutz
    ("Eigenschaften_Schweiz_Allgemein", "Verdunkelung", "label_verdunkelung"),
    ("Eigenschaften_Schweiz_Allgemein", "Schutzschicht", "label_schutzschicht"),
    ("Eigenschaften_Schweiz_Allgemein", "Sonnenschutz", "label_sonnenschutz"),
    # Allgemeine Bauteilklassifikation
    ("Eigenschaften_Schweiz_Allgemein", "Einbau", "label_einbau"),
    ("Eigenschaften_Schweiz_Allgemein", "Aufzugstyp", "label_aufzugstyp"),
]

# additional properties to extract directly from ifc
AC_PROPERTY_NAMES = [
    "ArchiCADProperties.Oberfläche (Alle)",
    "ArchiCADProperties.Ursprungsgeschoss Nummer",
    'ArchiCADQuantities.Abstand zu Ursprungsgeschoss',
    'ArchiCADQuantities.Höhe zu verknüpftem/Ursprungsgeschoss',
    'ArchiCADQuantities.Höhenangabe zum Projekt-Nullpunkt',
    'ArchiCADQuantities.Oberkante zu Projektursprung',
    'ArchiCADQuantities.Oberkante zu Ursprungsgeschoss',
    'ArchiCADQuantities.Unterkante zu Projektursprung',
    'ArchiCADQuantities.Unterkante zu Ursprungsgeschoss',
]

# entity types to ignore
IGNORE_TYPES = {"IfcSite", "IfcBuilding", "IfcBuildingStorey", "IfcOpeningElement", "IfcBuildingElementProxy"}

# internal helper functions

def _get_property(psets, pset_pattern, prop_name):
    """Return the first value of prop_name found in any pset matching pset_pattern."""
    # get property value with fuzzy pset name matching 
    for pset_name, props in psets.items():
        if fnmatch.fnmatch(pset_name, pset_pattern) and prop_name in props:
            value = props[prop_name]
            return str(value).lower()
    return None

def _extract_from_model(model, property_mapping):
    """Return {guid: {col: value, ...}} for every IfcProduct in model."""
    result = {}

    # iterate over all IfcProducts in the model and get their properties based on the property mapping
    for product in model.by_type("IfcProduct"):
        psets = ifcopenshell.util.element.get_psets(product)
        result[product.GlobalId] = {
            col: _get_property(psets, pset_pat, prop)
            for pset_pat, prop, col in property_mapping
        }
    return result
    
def _is_valid_material_part(name):
    """Filter out invalid material names, e.g. empty strings, abbreviations, or technical codes."""
    # remove empty or null names
    if not name:
        return False
    
    # remove if contains brackets
    if re.search(r'[()[\]]', name):
        return False
    
    # remove if last token contains any digit (e.g. "C30/37", "B25", "01")
    last_token = name.split()[-1] if name.split() else ""
    if re.search(r'\d', last_token):
        return False
    
    # remove 1–3 character tokens (abbreviations like "UG", "EG", "OG", "A", "mm")
    if len(name) <= 3:
        return False
    return True

def _clean_material_names(raw_names, split_pattern=None):
    """Splits by all delimiters, filters invalid parts, returns frozenset of cleaned names."""
    result = set()

    # split by common delimiters (space, comma, semicolon, slash) and clean each part
    for name in raw_names:
        for part in split_pattern.split(name):
            part = part.strip().lower()
            if _is_valid_material_part(part):
                result.add(part)
    return frozenset(result)

def _get_material_names(element):
    """Returns a list of all material names assigned to an IFC element (empty list if none)."""
    mat = ifcopenshell.util.element.get_material(element)
    if mat is None:
        return []
    else:
        # try all different ways materials can be assigned in IFC, and collect all material names
        if mat.is_a('IfcMaterialLayerSet'):
            return [l.Material.Name for l in mat.MaterialLayers if l.Material and l.Material.Name]
        if mat.is_a('IfcMaterialLayerSetUsage'):
            return [l.Material.Name for l in mat.ForLayerSet.MaterialLayers if l.Material and l.Material.Name]
        if mat.is_a('IfcMaterialConstituentSet'):
            return [c.Material.Name for c in mat.MaterialConstituents if c.Material and c.Material.Name]
        if mat.is_a('IfcMaterialProfileSet'):
            return [p.Material.Name for p in mat.MaterialProfiles if p.Material and p.Material.Name]
        if mat.is_a('IfcMaterialProfileSetUsage'):
            return [p.Material.Name for p in mat.ForProfileSet.MaterialProfiles if p.Material and p.Material.Name]
        if mat.is_a('IfcMaterial') and mat.Name:
            return [mat.Name]
        if mat.is_a('IfcMaterialList'):
            return [m.Name for m in mat.Materials if m and m.Name]
        
        return []

# main functions

def enrich_with_ifc_properties(parquet_path, output_path, property_mapping, ifc_base_dir):
    """ Extract the configured properties per element (matched by "guid"), and return the enriched DataFrame and save it. """

    if property_mapping is None:
        property_mapping = PROPERTY_MAPPING

    parquet_path = Path(parquet_path)
    base_dir = Path(ifc_base_dir) if ifc_base_dir else parquet_path.parent
    col_names = [col for _, _, col in property_mapping]

    df = pd.read_parquet(parquet_path)
    for col in col_names:
        df[col] = None

    unique_paths = df["ifc_file_path"].dropna().unique()
    print(f"Enriching {len(df):,} rows from {len(unique_paths)} IFC file(s) …\n")

    # iterate over unique IFC file paths, extract properties, and merge them back to the main DataFrame
    for raw_path in unique_paths:
        ifc_path = Path(raw_path)
        if not ifc_path.is_absolute():
            ifc_path = (base_dir / ifc_path).resolve()

        if not ifc_path.exists():
            print(f" File not found, skipping: {ifc_path}")
            continue

        print(f"Processing: {ifc_path.name}")
        guid_props = _extract_from_model(ifcopenshell.open(str(ifc_path)), property_mapping)

        patch = pd.DataFrame.from_dict(guid_props, orient="index")
        patch.index.name = "guid"
        patch = patch.reset_index()

        mask = df["ifc_file_path"] == raw_path
        merged = df.loc[mask, ["guid"]].merge(patch, on="guid", how="left")
        df.loc[mask, col_names] = merged[col_names].values

    if output_path is not None:
        output_path = Path(output_path)
        df.to_parquet(output_path, index=False)
        print(f"\nSaved {len(df):,} rows -> {output_path}")

    return df

def extract_excel_label_informations(excel_path):
    df = pd.read_excel(excel_path, dtype=str)

    # remove empty rows
    df = df.dropna(how="all")

    # remove rows without a Name
    df = df.dropna(subset=[df.columns[0]])
    
    df["excel_label_file_path"] = str(excel_path)
    df["excel_label_name"] = excel_path.stem
    return df.to_dict(orient="records")

def extract_ifc_main_properties(ifc_path):
    model = ifcopenshell.open(str(ifc_path))
    schema = model.schema

    records = []
    # get main properties of all IfcProducts exsiting in the model
    for product in model.by_type("IfcProduct"):
        predefined_type = getattr(product, "PredefinedType", None)
        records.append(
            {
                "file_path": str(ifc_path),
                "model_name": ifc_path.stem,
                "ifc_schema": schema,
                "guid": product.GlobalId,
                "ifc_entity": product.is_a(),
                "predefined_type": str(predefined_type) if predefined_type is not None else None,
            }
        )
    return records


def build_project_fingerprint(df, label_cols, count_bins=(1, 10, 100, 1000)):
    """ Binary fingerprint for each project, encoding whether it has at least N occurrences of each label value. Used for project-level stratification. """

    # sort project id's to ensure consistent ordering
    project_ids = np.sort(df["project_code"].dropna().unique())
    features = {}

    for col in label_cols:
        # get counts of each label value per project, reindex to include all projects, fill missing with 0
        counts = (
            df.groupby(["project_code", col])
              .size()
              .unstack(fill_value=0)
              .reindex(project_ids, fill_value=0)
        )

        # create a binary feature indicating if the project has at least that many occurrences
        for value in counts.columns:
            col_counts = counts[value].values

            # create binary features for each count threshold
            for threshold in count_bins:
                feature_name = f"{col}={value}__>={threshold}"
                features[feature_name] = (col_counts >= threshold).astype(int)

    # convert to DataFrame for easier handling
    fingerprint_df = pd.DataFrame(features, index=project_ids)

    return fingerprint_df.values, project_ids, list(fingerprint_df.columns)


def project_level_split(df, label_cols, test_size=0.10, val_size=0.20, random_state=SEED, count_bins=(1, 10, 100, 1000)):
    """ Project based split ond two levels. Stratification is based on a binary fingerprint of label distributions per project, to ensure similar label distributions across splits."""

    # get the binary fingerprint for each project based on label distributions
    fp, project_ids, _ = build_project_fingerprint(df, label_cols, count_bins)

    # create mapping of project_id to row indices for efficient lookup when mapping splits back to rows
    idx_by_project = {}
    for project_id in project_ids:
        idx_by_project[project_id] = np.where(df["project_code"] == project_id)[0]

    # create first split on project level (trainval and test)
    split1 = MultilabelStratifiedShuffleSplit(n_splits=1, test_size=test_size, random_state=random_state)
    trainval_pos, test_pos = next(split1.split(project_ids, fp))
    trainval_projects = project_ids[trainval_pos]
    test_projects     = project_ids[test_pos]

    # create second split on project level (train and val)
    split2 = MultilabelStratifiedShuffleSplit(n_splits=1, test_size=val_size, random_state=random_state)
    train_rel, val_rel = next(split2.split(trainval_projects, fp[trainval_pos]))
    train_projects = trainval_projects[train_rel]
    val_projects   = trainval_projects[val_rel]

    # map project splits back to row indices
    train_idx = np.concatenate([idx_by_project[p] for p in train_projects])
    val_idx   = np.concatenate([idx_by_project[p] for p in val_projects])
    test_idx  = np.concatenate([idx_by_project[p] for p in test_projects])

    # assert check to ensure no project is in more than one split
    assert set(train_projects).isdisjoint(val_projects)
    assert set(train_projects).isdisjoint(test_projects)
    assert set(val_projects).isdisjoint(test_projects)

    print(f"Count of projects in splits: {len(train_projects)} train | {len(val_projects)} val | {len(test_projects)} test")
    print(f"Projects in train split: {train_projects}")
    print(f"Projects in val split: {val_projects}")
    print(f"Projects in test split: {test_projects}")
    print(f"\nCount of elements in splits: {len(train_idx):,} | {len(val_idx):,} | {len(test_idx):,}")

    return train_idx, val_idx, test_idx, {
        "train_projects": train_projects,
        "val_projects": val_projects,
        "test_projects": test_projects,
    }


def drop_train_duplicates(df, train_idx, val_idx, test_idx, feature_cols):
    """ Removes rows from val and test sets that have identical feature vectors to any row in the train set, to prevent leakage."""
    
    # create train hashes as set and val/test hashes as Series to check for duplicates efficiently
    train_hashes = set(pd.util.hash_pandas_object(df.iloc[train_idx][feature_cols], index=False))
    val_hashes  = pd.util.hash_pandas_object(df.iloc[val_idx][feature_cols], index=False)
    test_hashes = pd.util.hash_pandas_object(df.iloc[test_idx][feature_cols], index=False)

    # check which val/test hashes are in train hashes (leakage) and filter them out
    val_leakage  = val_hashes.isin(train_hashes).values
    test_leakage = test_hashes.isin(train_hashes).values

    # create new indices for val and test without the leaked rows
    clean_val_idx  = val_idx[~val_leakage]
    clean_test_idx = test_idx[~test_leakage]

    print(f"Leakage deduplication: {val_leakage.sum()} rows from validation ds removed, {test_leakage.sum()} rows from test ds removed.")

    return train_idx, clean_val_idx, clean_test_idx


def drop_split_orphans(df, train_idx, val_idx, test_idx, target_cols):
    """Remove rows where label values are missing from any split. Repeats until stable."""
    # store all three splits in a list for easier iteration and updating during the loop
    splits = [np.array(train_idx), np.array(val_idx), np.array(test_idx)]

    changed = True
    while changed:
        changed = False

        # loop though target columns and ensure that for each column all orphans are removed from all splits
        for col in target_cols:
            # get unique non-null values for this column in each split
            col_data = df[col].dropna()
            values_per_split = [set(col_data.iloc[s].unique()) for s in splits]

            # find values that are common to all splits
            common_values = set.intersection(*values_per_split)

            # filter each split to only include rows where the column value is in the common values
            keep_masks = [df.iloc[s][col].isin(common_values).values for s in splits]
            filtered_splits = [s[mask] for s, mask in zip(splits, keep_masks)]

            # if any split got smaller, we need to check again with the new splits (in case this creates new orphans for other columns)
            if any(len(new) < len(old) for new, old in zip(filtered_splits, splits)):
                splits, changed = filtered_splits, True

    # print how many rows were removed from each split due to orphan removal
    n_removed = [len(orig) - len(final) for orig, final in zip([train_idx, val_idx, test_idx], splits)]
    print(f"Orphan removal: {n_removed[0]} train | {n_removed[1]} val | {n_removed[2]} test rows removed.")
    
    return splits[0], splits[1], splits[2]


def create_hf_dataset(df, feature_cols, target_cols, minor_cols, label_cols, test_size=0.10, val_size=0.20, random_state=SEED):
    """ Create a Hugging Face DatasetDict with splits on project level, stratified by label distributions, and with leakage deduplication."""
    all_label_cols = label_cols + minor_cols
    df_reset = df.reset_index(drop=True)

    # get project-level splits with stratification based on label distributions
    train_idx, val_idx, test_idx, project_info = project_level_split(
        df_reset, all_label_cols,
        test_size=test_size, val_size=val_size, random_state=random_state,
    )

    # remove duplicates from val and test sets to prevent leakage
    train_idx, val_idx, test_idx = drop_train_duplicates(
        df_reset, train_idx, val_idx, test_idx, feature_cols
    )

    # remove rows where label values are missing from any split
    train_idx, val_idx, test_idx = drop_split_orphans(
        df_reset, train_idx, val_idx, test_idx, target_cols
    )

    # helper function to build a Hugging Face Dataset from a subset of the DataFrame
    def build(idx):
        subset = df_reset.iloc[idx][feature_cols + target_cols].reset_index(drop=True)
        return Dataset.from_pandas(subset)

    dataset = DatasetDict({
        "train": build(train_idx),
        "validation": build(val_idx),
        "test": build(test_idx),
    })

    total = len(df_reset)
    print(f"\nTrain: {len(dataset['train'])} ({len(dataset['train'])/total*100:.1f}%) | "
          f"Val: {len(dataset['validation'])} ({len(dataset['validation'])/total*100:.1f}%) | "
          f"Test: {len(dataset['test'])} ({len(dataset['test'])/total*100:.1f}%)")

    return dataset, project_info

def oversample_training_data(df_train, label_cols, target_count=1000, random_state=SEED):
    """Multilabel oversampling for the training split using RandomOverSampler. Upsamples only label combinations with fewer than target_count samples. Returns the oversampled DataFrame."""

    # combine all label columns into a single 1D key for RandomOverSampler
    y_combined = df_train[label_cols].astype(str).agg("-".join, axis=1)

    # only upsample combinations below target_count as sampling strategy
    class_counts = y_combined.value_counts()
    sampling_strategy = {
        cls: target_count for cls, count in class_counts.items() if count < target_count
    }

    # apply RandomOverSampler to the training data with the defined sampling strategy
    ros = RandomOverSampler(sampling_strategy=sampling_strategy, random_state=random_state)
    df_res, _ = ros.fit_resample(df_train, y_combined)

    return df_res.sample(frac=1, random_state=random_state).reset_index(drop=True)


# helper function to show label distribution in the splits
def show_label_distribution(ds, cols):
    """Shows the distribution of values for the specified columns across the different splits in the Hugging Face DatasetDict. Returns a DataFrame with counts and percentages for each value in each split."""
    splits = {name: ds[name].to_pandas() for name in ds}
    rows = []
    for col in cols:
        # get all unique values for this column across all splits
        all_values = pd.concat(
            [df_split[col] for df_split in splits.values()], ignore_index=True).unique()

        # iterate over each unique value and calculate count and percentage for each split
        for val in sorted(all_values):
            row = {"feature": col, "value": val}
            for split_name, df_split in splits.items():
                count = (df_split[col] == val).sum()
                pct = count / len(df_split) * 100
                row[f"{split_name}"] = count
                row[f"{split_name}_pct"] = round(pct, 1)
            rows.append(row)
    return pd.DataFrame(rows).set_index(["feature", "value"])