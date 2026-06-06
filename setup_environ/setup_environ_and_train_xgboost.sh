#!/bin/bash

pip3 install poetry --quiet
if [ "$NO_PULL" = "true" ]; then
	echo "Skipping pulling the repository";
else
	# clone the repository, if it fails go into the folder and pull instead, if it succeeds, also go into the folder
	git clone "https://oauth2:$ACCESS_TOKEN@gitlab.com/Valairaa/hslu_baa_ebkph_classifier.git" || (cd hslu_baa_ebkph_classifier && git pull);
fi
cd hslu_baa_ebkph_classifier

echo "Installing dependencies..."
poetry install --quiet
echo "Dependencies installed"

# define the path to the notebook
NOTEBOOK_PATH="code/4_modeling/4_5_hyperparameter_tuning/hyperparameter_tuning_xgboost.ipynb"
OUTPUT_NAME="temp_executed_notebook"
OUTPUT_PATH="code/4_modeling/4_5_hyperparameter_tuning"

RUN_AS_DAEMON=true

# activate the poetry environment and convert the notebook to a script
poetry run jupyter nbconvert --ExecutePreprocessor.timeout=600 --to script $NOTEBOOK_PATH --output $OUTPUT_NAME
cd $OUTPUT_PATH
export WANDB_TOKEN="$WANDB_TOKEN"

# run the script based on the RUN_AS_DAEMON variable
if [ "$RUN_AS_DAEMON" = true ]; then
    echo "Running script as a daemon..."
    poetry run setsid python3 $OUTPUT_NAME.py > logfile_output_xgboost 2>&1 &
    echo "Script is running in the background. Logs can be found in logfile_output_xgboost."
else
    echo "Running script normally..."
    poetry run python3 $OUTPUT_NAME.py
fi