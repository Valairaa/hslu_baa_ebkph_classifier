import sys
import os
import uuid
import json
import itertools
import statistics
import wandb # type: ignore

sys.path.append("..")

from env_helper import load_dotenv  # type: ignore

# add project root to path without the need of installing the package
sys.path.insert(0, "../../")

# load env vars from .env if not already in environment (local dev)
from env_helper import get_env_var

WANDB_PROJECT = get_env_var("WANDB_PROJECT")
WANDB_ENTITY  = get_env_var("WANDB_ENTITY")

# sentinel value to encode None in sweep configs, wandb does not support None values
_NONE_SENTINEL = "__none__"


def _clean_slashes(s):
    return str(s).replace("/", "-")

def __get_wandb_token():
    token = os.getenv("WANDB_TOKEN")
    if not token:
        load_dotenv()
        token = os.getenv("WANDB_TOKEN")
    return token

def set_run_name(run, config_params=None):
    """Sets the wandb run name to a string of config param values, e.g. 'n_estimators_200_<uuid>'."""
    if run is None:
        return
    if config_params is not None:
        run_name = "_".join([f"{k}_{_clean_slashes(run.config[k])}" for k in config_params if k in run.config])
        run_name = f"{run_name}_{uuid.uuid4().hex[:6]}"
        wandb.run.name = run_name


def get_sweep_params(run):
    """Extracts sweep parameters from a wandb run config, decoding _NONE_SENTINEL back to None."""
    return {
        k: (None if v == _NONE_SENTINEL else v)
        for k, v in dict(run.config).items()
    }


def log_ml_metrics(run, eval_df, split=None):
    """Logs per-label and mean metrics from a ModelTrainer.evaluate() DataFrame to wandb."""
    if run is None:
        return
    metrics = {}
    for label, row in eval_df.iterrows():
        for col in eval_df.columns:
            inner = col if label == "mean" else f"{label}/{col}"
            key = f"{split}/{inner}" if split else inner
            metrics[key] = row[col]
    wandb.log(metrics)


def _build_run_record(run, sweep_id, sweep_name):
    """Extracts all params, metrics, and metadata from a wandb public-API Run object"""
    summary = dict(run.summary)
    config  = {k: v for k, v in run.config.items() if not k.startswith("_")}

    # not all metrics are scalar in wandb
    def _scalar_only(d):
        return {k: v for k, v in d.items() if isinstance(v, (int, float, str, bool))}

    metrics = _scalar_only(summary)

    # aggregate missing mean metrics from label values when not explicitly logged
    aggregates = {}
    for k, v in metrics.items():
        parts = k.split("/")
        if len(parts) == 3:
            agg_key = f"{parts[0]}/{parts[2]}"
            aggregates.setdefault(agg_key, []).append(v)

    for agg_key, values in aggregates.items():
        if agg_key not in metrics:
            metrics[agg_key] = sum(values) / len(values)

    return {
        "run_id": run.id,
        "run_name": run.name,
        "sweep_id": sweep_id,
        "sweep_name": sweep_name,
        "model_type": summary.get("model_type"),
        "oversampling": config.get("training_oversample"),
        "categories": summary.get("categories"),
        "feature_names": summary.get("feature_names"),
        "params": _scalar_only(config),
        "metrics": metrics,
    }


def list_sweeps(wandb_project=WANDB_PROJECT, wandb_entity=WANDB_ENTITY, output_path=None):
    """Returns all sweeps in the project as a list of {sweep_id, sweep_name}."""
    wandb_token = __get_wandb_token()
    wandb.login(key=wandb_token) if wandb_token else wandb.login()

    api = wandb.Api()
    sweeps = api.project(wandb_project, entity=wandb_entity).sweeps()
    result = [{"sweep_id": s.id, "sweep_name": s._attrs.get("displayName") or s.id} for s in sweeps]

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

    return result


def get_best_runs_from_sweep(sweep_id, wandb_project=WANDB_PROJECT, wandb_entity=WANDB_ENTITY, top_n=10, output_path=None, primary_metric="val/f1_macro"):
    """Fetches the top-N finished runs from a single sweep in one API call, sorted server-side by primary_metric descending."""
    wandb_token = __get_wandb_token()
    wandb.login(key=wandb_token) if wandb_token else wandb.login()

    api = wandb.Api()
    runs = api.runs(
        f"{wandb_entity}/{wandb_project}",
        filters={"sweep": sweep_id, "state": "finished"},
        order=f"-summary_metrics.{primary_metric}",
        per_page=top_n,
    )

    records = []
    for r in itertools.islice(runs, top_n):
        sweep_name = r.sweep._attrs.get("displayName") or sweep_id
        records.append(_build_run_record(r, sweep_id, sweep_name))

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(records, f, indent=2, ensure_ascii=False)

    return records


def get_best_runs_all_sweeps(wandb_project=WANDB_PROJECT, wandb_entity=WANDB_ENTITY, top_n=10, output_path="best_runs.json", primary_metric="val/f1_macro", secondary_metric="val/mcc"):
    """ Builds three sections: runs_per_sweep, best_by_sweep, best_by_model_type, each sorted by primary_metric descending."""
    wandb_token = __get_wandb_token()
    wandb.login(key=wandb_token) if wandb_token else wandb.login()

    api = wandb.Api()
    sweeps = list(api.project(wandb_project, entity=wandb_entity).sweeps())

    primary_key = primary_metric.replace("/", "_")
    secondary_key = secondary_metric.replace("/", "_")

    def _metric_val(record, metric):
        return record["metrics"].get(metric, float("-inf"))

    def _best_run_for(sweep_id, sweep_name, oversample_val, metric):
        """One API call: best run for a given sweep + oversampling flag + metric."""
        runs = api.runs(
            f"{wandb_entity}/{wandb_project}",
            filters={"sweep": sweep_id, "state": "finished", "config.training_oversample": oversample_val},
            order=f"-summary_metrics.{metric}",
            per_page=1,
        )
        run = next(iter(runs), None)
        return _build_run_record(run, sweep_id, sweep_name) if run else None

    # get top-n runs for each sweep (server-side)
    runs_per_sweep = {}
    all_records    = []

    for sweep in sweeps:
        sweep_id = sweep.id
        sweep_name = sweep._attrs.get("displayName") or sweep_id

        sweep_runs = api.runs(
            f"{wandb_entity}/{wandb_project}",
            filters={"sweep": sweep_id, "state": "finished"},
            order=f"-summary_metrics.{primary_metric}",
            per_page=top_n,
        )

        records = [_build_run_record(r, sweep_id, sweep_name) for r in itertools.islice(sweep_runs, top_n)]
        runs_per_sweep[sweep_id] = records
        all_records.extend(records)

    # get best runs with and without oversampling for each sweep
    best_by_sweep = {}

    for sweep in sweeps:
        sweep_id = sweep.id
        sweep_name = sweep._attrs.get("displayName") or sweep_id
        entry = {"sweep_name": sweep_name}

        for oversample_val, label in [(True, "oversampling"), (False, "no_oversampling")]:
            best_f1 = _best_run_for(sweep_id, sweep_name, oversample_val, primary_metric)
            best_mcc = _best_run_for(sweep_id, sweep_name, oversample_val, secondary_metric)
            if best_f1 or best_mcc:
                entry[label] = {}
                if best_f1:
                    entry[label][f"best_{primary_key}"]   = best_f1
                if best_mcc:
                    entry[label][f"best_{secondary_key}"] = best_mcc

        best_by_sweep[sweep_id] = entry

    # get best runs by model type and oversampling across all sweeps
    def _report_record(record):
        return {
            "run_id": record["run_id"],
            "run_name": record["run_name"],
            "sweep_id": record["sweep_id"],
            "sweep_name": record["sweep_name"],
            "model_type": record["model_type"],
            "oversampling": record["oversampling"],
            "feature_names": record["feature_names"],
            "params": record["params"],
            "metrics": {
                primary_metric: record["metrics"].get(primary_metric),
                secondary_metric: record["metrics"].get(secondary_metric),
            },
        }

    # get best runs by model type and oversampling across all sweeps
    groups = {}
    for entry in best_by_sweep.values():
        for label in ("oversampling", "no_oversampling"):
            if label not in entry:
                continue
            for record in entry[label].values():
                if not record or not record.get("model_type"):
                    continue
                oversampling = label == "oversampling"
                groups.setdefault((record["model_type"], oversampling), []).append(record)

    # for each model type, get the best runs with and without oversampling, sorted by primary_metric
    best_by_model_type = {}
    for (model_type, oversampling), group in groups.items():
        label = "oversampling" if oversampling else "no_oversampling"
        best_f1_run = max(group, key=lambda r: _metric_val(r, primary_metric))
        best_mcc_run = max(group, key=lambda r: _metric_val(r, secondary_metric))

        best_by_model_type.setdefault(model_type, {})[label] = {
            f"best_{primary_key}": _report_record(best_f1_run),
            f"best_{secondary_key}": _report_record(best_mcc_run),
        }

    result = {
        "runs_per_sweep": runs_per_sweep,
        "best_by_sweep": best_by_sweep,
        "best_by_model_type": best_by_model_type,
    }

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

    return result

def get_best_by_model_type(input_path="best_runs.json", output_path="best_by_model_type.json"):
    """Extracts best_by_model_type from best_runs.json and saves it to output_path."""
    with open(input_path, encoding="utf-8") as f:
        data = json.load(f)

    result = data["best_by_model_type"]

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

    return result


def get_training_stats(wandb_project=WANDB_PROJECT, wandb_entity=WANDB_ENTITY, models=("random_forest", "xgboost"), output_path="training_stats.json"):
    """Fetches all finished runs for the given model types and computes count, mean, and median of training duration, grouped by model type and oversampling flag."""
    wandb_token = __get_wandb_token()
    wandb.login(key=wandb_token) if wandb_token else wandb.login()

    api = wandb.Api()
    runs = api.runs(f"{wandb_entity}/{wandb_project}", filters={"state": "finished"}, per_page=500)

    buckets = {}
    for run in runs:
        model_type = run.summary.get("model_type")
        duration = run.summary.get("train_duration_s")

        if model_type not in models or duration is None:
            continue

        oversample = run.config.get("training_oversample", False)
        buckets.setdefault((model_type, bool(oversample)), []).append(float(duration))

    def _stats(times):
        return {"count": len(times), "mean_seconds": round(statistics.mean(times), 2), "median_seconds": round(statistics.median(times), 2)}

    result = {}
    
    for (model_type, oversample), times in buckets.items():
        result.setdefault(model_type, {})["oversampling" if oversample else "no_oversampling"] = _stats(times)

    for model_type in result:
        all_times = [t for (mt, _), ts in buckets.items() if mt == model_type for t in ts]
        result[model_type]["total"] = _stats(all_times)

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)

    return result


def start_training(train_and_load_func, use_wandb=True, sweep_config=None, wandb_project=None, wandb_entity=None, sweep_count=None):
    """Starts the training process, optionally using wandb sweeps for hyperparameter tuning."""
    if use_wandb is False:
        train_and_load_func()
        return
    wandb_token = __get_wandb_token()
    wandb.login(key=wandb_token) if wandb_token else wandb.login()
    sweep_id = wandb.sweep(sweep=sweep_config, project=wandb_project, entity=wandb_entity)

    if sweep_count is not None and sweep_count <= 0:
        sweep_count = None

    wandb.agent(sweep_id, function=train_and_load_func, count=sweep_count) if sweep_count else wandb.agent(sweep_id, function=train_and_load_func)
    wandb.finish()