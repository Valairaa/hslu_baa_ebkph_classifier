# AI-Based Building-Element Classification for eBKP-H

This repository contains the full source code, experiments and written report of a Bachelor's thesis that builds a machine-learning quality-assurance (QA) tool for [BIM](https://en.wikipedia.org/wiki/Building_information_modeling) models. Given an arbitrary, "uncleaned" IFC model, the final pipeline extracts geometric features per building element, predicts four classification labels with a soft-vote ensemble, and reports anomalies back to domain experts as importable **BCF**, **Excel** and **JSON** feedback reports.

This is the first work to apply ML to the classification of building elements for an [**eBKP-H**](https://www.crb.ch/de/normen-standards/baukostenplane/baukostenplan-hochbau-ebkp-h) (Swiss standardized construction cost classification) mapping, and it is intended as a foundation for AI-assisted QA in this domain.

---

## Table of contents

- [Motivation & problem](#motivation--problem)
- [Approach](#approach)
- [Key results](#key-results)
- [The four predicted labels](#the-four-predicted-labels)
- [Geometric features (73 features in 6 categories)](#geometric-features-73-features-in-6-categories)
- [Repository structure](#repository-structure)
- [Pipeline (CRISP-DM)](#pipeline-crisp-dm)
- [Helper modules](#helper-modules)
- [Installation](#installation)
- [Usage](#usage)
- [Data & confidentiality](#data--confidentiality)
- [The written report](#the-written-report)
- [Project context](#project-context)
- [License & acknowledgements](#license--acknowledgements)

---

## Motivation & problem

In the construction industry, model-based cost estimation according to eBKP-H requires building elements in IFC models to be classified consistently and correctly. In practice this is:

- **error-prone**: IFC export from native CAD software loses internal classification information, the IFC schema allows many valid representations of the same object, and elements are often modelled as the generic `IfcBuildingElementProxy`
- **time-consuming**: classification and the deterministic eBKP-H mapping are largely manual today
- **expert-dependent**: rule-based assignment is subjective, hard to standardize and brittle to changes

The industry partner [GKS Architekten AG](https://www.gks.ch) already performs model-based eBKP-H cost estimation and faces exactly these data-preparation and maintenance challenges. The goal of this thesis is a model that flags anomalies in informed building elements and reports them in a plausible, readable way to support QA. This approach will strengthen the manual classification process rather than replacing it.

## Approach

A central design decision: instead of predicting eBKP-H codes directly, the pipeline predicts the properties (labels) that the deterministic IDC AG assignment matrix needs to map an element to an eBKP-H code. This keeps results interpretable (you can see which property is wrong), robust to changes in the mapping table, and well-suited to a class-imbalanced dataset.

The work follows the **CRISP-DM** process and an empirical-experimental methodology testing two hypotheses:

1. Geometric features alone are sufficient to predict the relevant labels with a Macro-F1 ≥ 0.70 per label.
2. Gradient-boosting methods (XGBoost) reach comparable performance to Random Forest at shorter training time on identical hardware.

### Highlights:

- **13 real projects** (new builds and renovations of varying size and SIA phase) provided as IFC + Solibri files and 4 of the 13 relevant labels had enough data to train on.
- **73 geometric features** are extracted per element across six categories (see below). The geometry is the only reliable source of truth that survives an IFC export.
- **Project-level, stratified train/validation/test split** (72 % / 18 % / 10 %) so no project appears in more than one split, plus removal of identical feature vectors and classes missing from a split preventing data leakage.
- **Rare-class threshold analysis** (keep classes with ≥ 200 training samples) and **multilabel oversampling** of under-represented label combinations on the training split only.
- **One model per label** for classical ML and the MLP predicts all four labels jointly via a shared backbone with one classification head per label.
- **Hyperparameter tuning** with [Weights & Biases](https://wandb.ai) sweeps (Grid Search for RF, Bayesian Optimization for XGBoost and the MLP), driven by feature-group and Top-N feature-selection analyses.
- **Final model = soft-vote ensemble** of the best RF, XGBoost and MLP, with **per-label confidence thresholds** so only practically useful predictions are reported (trading coverage for precision).

## Key results

Final soft-vote ensemble on the held-out **test set** (projects `ADEM` and `LUMU`, never seen during training):

| Metric | Value |
|---|---|
| Mean Macro-F1 (across 4 labels) | **0.7368** |
| Mean Accuracy | **77.32 %** |

With the tuned per-label **confidence thresholds** applied (covering > 70 % of elements):

- IfcEntity accuracy rises to **99.26 %**
- Location (`is_external`) accuracy rises to **93.92 %**

### Hypotheses:

- **H1 — partially confirmed.** The mean Macro-F1 (0.7368) exceeds 0.70, and three labels (IfcEntity, location, load-bearing) clear the bar individually. Only *predefined type* falls short at **0.5477** because the model often specifies elements more precisely than the ground truth, which is acceptable (and even useful) in practice.
- **H2 — performance confirmed, training time refuted.** XGBoost matched/beat RF on quality, but in this use case it took on average **23.04 s longer** to train than RF (boosting builds trees sequentially, RF in parallel).

The prototype was validated with the industry partner and will be put into production as a monthly **"PreCheck"** for internal QA.

## The four predicted labels

Defined in [code/_settings.py](code/_settings.py):

| Label | Meaning | Notes |
|---|---|---|
| `label_ifc_entity` | IFC entity / main class (e.g. `IfcWall`, `IfcSlab`, `IfcWindow`) | Always informed in the models |
| `label_predefined_type` | Predefined type refining the entity (e.g. `SOLIDWALL`, `PARTITIONING`) | Always informed; hardest label |
| `label_is_external` | Location: external vs. internal (`true` / `false` / `unknown`) | Informed for > 50 % of elements |
| `label_load_bearing` | Load-bearing vs. non-load-bearing (`true` / `false` / `unknown`) | Informed for > 50 % of elements |

`NaN` values (e.g. a plasterboard wall has no meaningful "load-bearing" value) are kept as an explicit `unknown` class rather than dropped, turning the missing-value problem into a structured classification problem.

## Geometric features (73 features in 6 categories)

Extracted per element in [code/geometric_extraction_helper.py](code/geometric_extraction_helper.py) from the IfcOpenShell triangulated mesh:

| Category | Prefix | Examples |
|---|---|---|
| **General geometry** | `geom_` | volume, surface area, projected (footprint) area, centroid, z-range, area/volume ratio, compactness, layer count |
| **Axis-aligned bounding box (AABB)** | `aabb_` | min/max per axis, edge lengths, side ratios, diagonal, box volume |
| **Object-aligned bounding box (TFBB)** | `tfbb_` | PCA-based extents, ratios, linearity, planarity, sphericity, primary axis (an O(n) alternative to the expensive caliper algorithm) |
| **Topology** | `topo_` | vertex/face/edge counts, Euler characteristic, genus, max/avg face area, vertex–edge ratio, connected components |
| **Materials** | `mat_` | binary tokens for materials found in the element's layers (e.g. concrete, insulation, brick, glass) |
| **Ray-cast neighbours** | `horizontal_elements_above/below` | count of horizontal elements directly above/below via ray-casting with a 1 m offset (to distinguish slabs, roofs and base slabs) |

## Repository structure

```
.
├── code/                                    # All source code (helpers + CRISP-DM notebooks)
│   ├── _settings.py                         # Labels, model config, splits, confidence thresholds, trained classes
│   ├── dataloader.py                        # IFC label extraction, project-level stratified split, oversampling
│   ├── geometric_extraction_helper.py       # The 73-feature extraction
│   ├── ml_models.py                         # sklearn model pipelines (baselines + tree ensembles)
│   ├── nn_models.py                         # PyTorch MLP (shared backbone + per-label heads)
│   ├── models_helper.py                     # Training, evaluation, feature importance, threshold sweeps
│   ├── ensemble_helper.py                   # Subprocess-based soft-vote ensemble inference
│   ├── feedback_helper.py                   # BCF / Excel / JSON report generation
│   ├── wandb_helper.py                      # W&B sweep tracking and querying
│   ├── dataviz_helper.py                    # Reusable plots and tables
│   ├── run_ensemble_model_prediction.py     # Per-model inference runner (one subprocess per model)
│   ├── run_demo.py                          # End-to-end demo pipeline (DemoFeedbackGenerator)
│   ├── code/ ...                            # CRISP-DM stage folders with notebooks (see below)
│   └── 6_deployment/demo_feedback.ipynb     # Demo entry point
├── chapters/                                # The written report (Typst), one folder per chapter
├── template/                                # Typst report template (HSLU)
├── meetings/                                # Supervision meeting minutes
├── web_abstract/                            # Web abstract (German)
├── setup_environ/                           # Shell scripts to set up env and launch training on a GPU host
├── pyproject.toml / poetry.lock             # Poetry dependency management
└── Stoeckli_Lukas_Bericht ... .pdf / .typ   # Final signed report
```

## Pipeline (CRISP-DM)

The notebooks orchestrate the helper modules and are organized by CRISP-DM phase:

| Stage | Folder | What it does |
|---|---|---|
| **0 — Data** | [code/0_data/](code/0_data/) | Raw IFC models, eBKP-H mapping lists, GKS code examples |
| **1 — Data mapping** | [code/1_data_mapping/](code/1_data_mapping/) | Collect data & labels, merge Solibri labels with IFC elements |
| **2 — Data understanding** | [code/2_data_understanding/](code/2_data_understanding/) | Split eBKP-H codes, visualize distributions |
| **3 — Curation & enrichment** | [code/3_data_curation_enrichement/](code/3_data_curation_enrichement/) | Extract labels & geometric features, analyze materials/features, dataset splitting, rare-class & oversampling thresholds |
| **4 — Modeling** | [code/4_modeling/](code/4_modeling/) | Train baseline & advanced ML models, feature importance, feature-selection analysis, hyperparameter tuning |
| **5 — Evaluation** | [code/5_evaluation/](code/5_evaluation/) | Best W&B runs, evaluate best models, soft-vote ensemble, misclassification analysis, confidence-threshold analysis |
| **6 — Deployment** | [code/6_deployment/](code/6_deployment/) | Demo feedback pipeline on whole IFC models |

## Helper modules

| Module | Responsibility |
|---|---|
| [dataloader.py](code/dataloader.py) | Extract labels from IFC, project-level stratified splitting, leakage deduplication, oversampling |
| [geometric_extraction_helper.py](code/geometric_extraction_helper.py) | Extract the six feature categories per element |
| [ml_models.py](code/ml_models.py) / [nn_models.py](code/nn_models.py) | Model definitions with model-specific preprocessing pipelines |
| [models_helper.py](code/models_helper.py) | Training, evaluation, feature-importance and threshold analysis |
| [wandb_helper.py](code/wandb_helper.py) | Tracking and querying sweep results |
| [ensemble_helper.py](code/ensemble_helper.py) | Subprocess-based inference and soft-vote aggregation |
| [feedback_helper.py](code/feedback_helper.py) | BCF, JSON and Excel report generation |
| [dataviz_helper.py](code/dataviz_helper.py) | Reusable plot and table output |
| [run_demo.py](code/run_demo.py) | The demo pipeline script |

> **Note on Apple Silicon:** importing XGBoost, scikit-learn and PyTorch in a single interpreter caused a `libomp`/OpenMP collision and kernel crash. The ensemble therefore runs **each model in its own Python subprocess** (`run_ensemble_model_prediction.py`), orchestrated in parallel by `EnsemblePredictor` in [ensemble_helper.py](code/ensemble_helper.py).

## Installation

Requires **Python 3.13–3.14** and [Poetry](https://python-poetry.org).

```bash
# install dependencies into a local .venv
poetry install
```

The PyTorch build is pulled from the CUDA 12.1 wheel index (see [pyproject.toml](pyproject.toml)), on Apple Silicon / CPU it falls back to the available backend at runtime (MPS -> CPU).

If you use [Weights & Biases](https://wandb.ai) for the tuning notebooks, provide credentials via a `.env` file in the repo root (loaded by [code/env_helper.py](code/env_helper.py)):

```
WANDB_TOKEN=<your-token>
```

## Usage

### Run the demo on a single IFC model

The simplest entry point is `DemoFeedbackGenerator` in [code/run_demo.py](code/run_demo.py), used by [code/6_deployment/demo_feedback.ipynb](code/6_deployment/demo_feedback.ipynb):

```python
from run_demo import DemoFeedbackGenerator

generator = DemoFeedbackGenerator(
    ifc_path="path/to/model.ifc",
    out_dir="./feedback/",
    project_id="MY_PROJECT",
)
generator.run()
```

This will:

1. **Extract** the four labels (from the `IfcProduct` hierarchy and property sets) and the 73 geometric features (optionally cached as a `*_extracted.parquet` next to the IFC).
2. **Preprocess** — drop elements with unresolvable geometry, fill missing `mat_`/`ray` features with `-1`.
3. **Predict** with the soft-vote ensemble and apply the per-label confidence thresholds (predictions below threshold are withheld as `NaN`).
4. **Generate reports** — a `.bcf` (one issue group per misclassification bucket, importable into ArchiCAD/Solibri), an `.xlsx` (overview / misclassified / correct / unchecked sheets), and a `.json`.

### Run ensemble inference directly

```bash
# predict on a parquet file with one model (writes preds + per-class probabilities)
python code/run_ensemble_model_prediction.py xgboost --input data.parquet --out-dir preds/
```

Loading the best checkpoints requires the tuned model pickles under `code/4_modeling/4_5_hyperparameter_tuning/models/` (gitignored — see below).

### Reproduce training / tuning

Work through the CRISP-DM notebooks in order (stages 1 to 6). The shell scripts in [setup_environ/](setup_environ/) clone the repo, install dependencies, convert a tuning notebook to a script and launch it (optionally as a background daemon). It was used to run sweeps on the HSLU [GPUHub](https://gpuhub.labservices.ch) (NVIDIA A16).

## Data & confidentiality

The IFC models and labels were provided by the industry partner and are **not included** in this repository. The following are intentionally gitignored (see [.gitignore](.gitignore)):

- `code/0_data/*` — raw IFC models and mapping lists
- `code/4_modeling/4_5_hyperparameter_tuning/models/*` — trained checkpoints
- `code/4_modeling/4_5_hyperparameter_tuning/wandb/*` — W&B run logs
- `.env`

An **anonymized subset** of the dataset is published on Kaggle: [BIM: Geometric Features for eBKP-H Classification](https://www.kaggle.com/datasets/lukasstoeckli/geometric-features-for-ebkp-h-classification).

## The written report

The thesis is written in [Typst](https://typst.app). Source lives in [chapters/](chapters/) (one folder per chapter) with the HSLU template in [template/](template/). The compiled, signed PDF is included in the repo root. Chapters: **1 Problem · 2 Research · 3 Methods · 4 Implementation · 5 Evaluation · 6 Outlook · 7 Appendix**. The report is written in German.

## Project context

| | |
|---|---|
| **Author** | Lukas Stöckli |
| **Degree** | BSc Artificial Intelligence & Machine Learning |
| **University** | Lucerne University of Applied Sciences and Arts (HSLU), Informatik |
| **Advisor** | Prof. Dr. Aljosa Smolic |
| **External expert** | Adrian Willi |
| **Industry partner** | [GKS Architekten AG](https://www.gks.ch) (Patrick Muff) |
| **Term** | Spring 2026 (FS26) |

## License & acknowledgements

This project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). The Typst report framework is based on [CtrlHaltDefeat/hslu_baa_typst](https://github.com/CtrlHaltDefeat/hslu_baa_typst).