#!/usr/bin/env Rscript
# ---------------------------
# Trains and tests all models and outputs results and figures
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

######################### Setup
library(tidyverse)
library(tidymodels)
library(here)
library(themis)
library(workflowsets)
library(glmnet)

# Metrics for model evaluation
hab_metrics <- metric_set(roc_auc, sens, yardstick::spec, accuracy)

######################### Preparing data

# Reading in data
hab_data <- read.csv(here("data", "data_prep", "combined.csv")) %>%
    # Filtering out samples that don't have microcystin information for the following week
    filter(!is.na(category_d_ahead)) %>%
    mutate(category_d_ahead = as.factor(category_d_ahead))



######################### Defining tidymodels recipes (data processing steps)

# Defining the base recipe which we'll build off for other workflows.
# This contains all the data processing steps common to every workflow
base_recipe <- recipe(formula = category_d_ahead ~ ., data = hab_data) %>%
    step_zv(all_predictors()) %>%
    step_rm(c(
        week, collected_date, environmental_location, category_d, Station,
        site_latitude, site_longitude, Station
    )) %>%
    step_impute_knn(all_numeric_predictors(), neighbors = 5) %>%
    step_normalize(all_numeric_predictors()) %>%
    step_mutate(mcya_16s = replace_na(mcya_16s, 0))

# Defining under- and oversampling recipes
downsample_recipe <- base_recipe %>%
    step_downsample(category_d_ahead)

oversample_recipe <- base_recipe %>%
    step_smote(category_d_ahead)


######################### Defining tidymodels models

# Defining the XGBoost model and setting the parameters that we'll tune
xgboost_spec <- boost_tree(
    trees = tune(),
    min_n = tune(),
    mtry = tune(),
    tree_depth = tune(),
    learn_rate = tune(),
    loss_reduction = tune(),
    sample_size = tune()
) %>%
    set_mode("classification") %>%
    set_engine("xgboost")

# Defining the logistic regression model. Note that parameter tuning doesn't work
# with models from the glm package
log_reg_spec <- logistic_reg(penalty = tune(), mixture = tune()) %>%
    set_engine("glmnet")


######################### Defining the workflow sets

# This defines a workflow set, which will train and evaluate all combinations of
# models and preprocessing recipes
hab_models_1 <- workflow_set(
    preproc = list(downsampled = downsample_recipe, oversampled = oversample_recipe),
    models = list(xgboost = xgboost_spec, log_reg = log_reg_spec),
    cross = TRUE
)


# Define cross-validation splits. We use 7 folds here because the number of
# hazardous samples is 70 and this leads to nicer training/testing splits.
set.seed(489)
cv_splits <- vfold_cv(hab_data, strata = category_d_ahead, v = 7)

# Model training. This will perform vfold cross-validation for each model configuration (defined)
# by the variables above set to tune and grid = 10) and sampling strategy.
hab_models_1 <- hab_models_1 %>%
    workflow_map(
        "tune_grid",
        resamples = cv_splits,
        grid = 10,
        metrics = hab_metrics, verbose = TRUE
    )

all_results <- rank_results(hab_models_1, rank_metric = "roc_auc") %>%
    select(rank, wflow_id, .metric, mean, std_err, model) %>%
    mutate(sampling_strategy = str_split(wflow_id, "_", simplify = TRUE)[, 1])

# Write out best model performance to a csv
write.csv(
    all_results,
    here("data/model_training", "training_results_all.csv"),
    row.names = FALSE,
    quote = FALSE
)


# Get metrics. select_best is set to TRUE so that the model configuration
# for each set of sampling strategy and model that achieves the highest roc_auc
# is selected.
best_results <- rank_results(hab_models_1, select_best = TRUE, rank_metric = "roc_auc") %>%
    select(rank, wflow_id, .metric, mean, std_err, model) %>%
    mutate(sampling_strategy = str_split(wflow_id, "_", simplify = TRUE)[, 1])

# Write out best model performance to a csv
write.csv(
    best_results,
    here("data/model_training", "training_results_best.csv"),
    row.names = FALSE,
    quote = FALSE
)

test <- rank_results(hab_models_1, select_best = TRUE, rank_metric = "roc_auc")
all_results %>%
    select(.config)
