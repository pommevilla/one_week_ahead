#!/usr/bin/env Rscript
# ---------------------------
# Trains and tests all models and outputs results and figures
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

######################### Setup
library(tidyverse)
library(tidymodels)
library(here)
library(keras)
library(themis)
library(workflowsets)
library(glmnet)
library(pROC)
library(finetune)

source("code/model_training/model_training_helpers.R")

# Metrics for model evaluation
hab_metrics <- metric_set(roc_auc, sens, yardstick::spec, accuracy)

######################### Preparing data

# Reading in data
hab_data_raw <- read.csv(here("data", "data_prep", "combined_normalized.csv")) %>%
    # Filtering out samples that don't have microcystin information for the following week
    filter(!is.na(category_d_ahead)) %>%
    mutate(category_d_ahead = as.factor(category_d_ahead))

# Reading in feature importances
feature_importances <- read.csv("data/model_training/feature_importances.csv")

# We say a feature is important if it's average normalized importance
# was greater than 0. This indicates that its predictive power was greater than average.
important_features <- feature_importances %>%
    filter(a_n_importance > 0) %>%
    pull("variable")


# Filtering down the total dataset to just the important features and the metadata needed
# for model training
hab_data <- hab_data_raw %>%
    select(all_of(important_features), category_d_ahead)

set.seed(130)
hab_data_split <- initial_split(hab_data, strata = category_d_ahead)
hab_train <- training(hab_data_split)
hab_test <- testing(hab_data_split)

######################### Defining tidymodels recipes (data processing steps)

# Defining the base recipe which we'll build off for other workflows.
# We performed all of the preprocessing in the data prep steps.
base_recipe <- recipe(formula = category_d_ahead ~ ., data = hab_train)

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

# Defining the logistic regression model.
log_reg_spec <- logistic_reg(penalty = tune(), mixture = tune()) %>%
    set_engine("glmnet")

nn_spec <- mlp(
    hidden_units = tune(),
    penalty = tune(),
    epochs = tune(),
    learn_rate = tune(),
    activation = tune()
) %>%
    set_mode("classification") %>%
    set_engine("brulee")


######################### Defining the workflow sets

# This defines a workflow set, which will train and evaluate all combinations of
# models and preprocessing recipes
hab_models_1 <- workflow_set(
    preproc = list(downsampled = downsample_recipe, oversampled = oversample_recipe),
    models = list(xgboost = xgboost_spec, log_reg = log_reg_spec, nn = nn_spec),
    cross = TRUE
)

# Define cross-validation splits. We use 7 folds here because the number of
# hazardous samples is 70 and this leads to nicer training/testing splits.
set.seed(489)
cv_splits <- vfold_cv(hab_train, strata = category_d_ahead, v = 7)

# Setting up parameters to pass to the workflow_map call just below
race_controls <- control_race(
    parallel_over = "everything"
)

# Model training. This will perform vfold cross-validation for each model configuration (defined)
# by the variables above set to tune and grid = 10) and sampling strategy.
hab_models_1 <- hab_models_1 %>%
    workflow_map(
        "tune_grid",
        resamples = cv_splits,
        grid = 2,
        metrics = hab_metrics,
        verbose = TRUE,
        seed = 1834,
        control = race_controls
    )


######## Naive model
# Our naive model predicts the next week's status to be whatever the
# current week's status is.


confusion_table <- table(
    hab_data_raw[, "category_d"],
    hab_data_raw[, "category_d_ahead"]
)

naive_guesses <- hab_data_raw %>%
    filter(!is.na(category_d)) %>%
    select(category_d) %>%
    mutate(prob = 1)

naive_auc <- auc(naive_guesses$category_d, naive_guesses$prob) %>%
    as.numeric()



######### Results
# These are the results from model training, plus the metrics from the
# naive model
all_results <- rank_results(hab_models_1, rank_metric = "roc_auc") %>%
    select(rank, wflow_id, .metric, mean, std_err, model) %>%
    mutate(sampling_strategy = str_split(wflow_id, "_", simplify = TRUE)[, 1]) %>%
    add_naive_results(confusion_table, naive_auc)

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
    mutate(sampling_strategy = str_split(wflow_id, "_", simplify = TRUE)[, 1]) %>%
    add_naive_results(confusion_table, naive_auc)

# Write out best model performance to a csv
write.csv(
    best_results,
    here("data/model_training", "training_results_best.csv"),
    row.names = FALSE,
    quote = FALSE
)


################## Testing results
# We'll only evaluate the testing results of the best model for each configuration.
testing_results_df <- data.frame()
for (x in hab_models_1$wflow_id) {
    best_model <- hab_models_1 %>%
        extract_workflow_set_result(x) %>%
        select_best(metric = "roc_auc")

    test_results <- hab_models_1 %>%
        extract_workflow(x) %>%
        finalize_workflow(best_model) %>%
        last_fit(split = hab_data_split, metrics = hab_metrics) %>%
        collect_metrics()

    x <- str_split(x, "_", 2)[[1]]
    this_sampling_strategy <- x[1]
    this_model <- x[2]

    test_results <- test_results %>%
        pivot_wider(names_from = ".metric", values_from = ".estimate") %>%
        mutate(
            sampling_strategy = this_sampling_strategy,
            model = this_model
        ) %>%
        select(sampling_strategy, model, sens:roc_auc)

    print(test_results)
    testing_results_df <- rbind(
        testing_results_df,
        test_results
    )
}

testing_results <- testing_results_df %>%
    add_row(
        sampling_strategy = "naive",
        model = "naive",
        sens = calc_sensitivity(confusion_table),
        spec = calc_specificity(confusion_table),
        accuracy = calc_accuracy(confusion_table),
        roc_auc = naive_auc
    )

write.csv(
    testing_results,
    here("data/model_training", "testing_results.csv"),
    row.names = FALSE,
    quote = FALSE
)
