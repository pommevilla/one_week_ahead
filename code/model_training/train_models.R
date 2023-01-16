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

theme_set(theme_minimal())


# Metrics for model evaluation
hab_metrics <- metric_set(roc_auc, sens, yardstick::spec, accuracy)


create_results_df <- function(num_rows = 0, num_cols = 4) {
    results_df <- data.frame(
        matrix(nrow = 0, ncol = 4)
    )

    colnames(results_df) <- c(".metric", ".estimator", ".estimate", ".config")

    return(results_df)
}

# These results df are to record the results and model configurations from the
# training process.
testing_results_df <- create_results_df()
training_results_df <- create_results_df()



######################### Preparing data

# Reading in data
hab_data <- read.csv(here("data", "data_prep", "combined.csv")) %>%
    # Filtering out samples that don't have microcystin information for the following week
    filter(!is.na(category_d_ahead))




######################### Defining tidymodels recipes (data processing steps)

# Defining the base recipe which we'll build off for other workflows.
# This contains all the data processing steps common to every workflow
base_recipe <- recipe(formula = category_d_ahead ~ ., data = hab_data) %>%
    step_zv(all_predictors()) %>%
    step_rm(c(week, collected_data, environmental_location, category_d)) %>%
    step_impute_knn(all_numeric_predictors(), neighbors = 5) %>%
    step_normalize(all_numeric_predictors())

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
log_reg_spec <- logistic_reg() %>%
    set_engine("glm")


######################### Defining the workflow sets

# This defines a workflow set, which will train and evaluate all combinations of
# models and preprocessing recipes
hab_models_1 <- workflow_set(
    preproc = list(downsampled = downsample_recipe, oversampled = oversample_recipe),
    models = list(xgboost = xgboost_spec, log_reg = log_reg_spec),
    cross = TRUE
)


# Define tuning grids

# Run model training

# Get metrics

# Output metrics

# Save models
