#!/usr/bin/env Rscript
# ---------------------------
# Removes different classes of variables (land use, climate) to see how their
# inclusion affects model performance.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

######################### Setup
library(tidyverse)
library(tidymodels)
library(here)
library(themis)
library(workflowsets)
library(glmnet)
library(pROC)
library(finetune)
library(stacks)

source("code/model_training/model_training_helpers.R")

# Metrics for model evaluation
hab_metrics <- metric_set(roc_auc, sens, yardstick::spec, accuracy)

######################### Preparing data
# Reading in data. Samples without microcystin information
# for the following week are filtered out.
hab_data_raw <- read.csv(here("data", "data_prep", "combined_normalized.csv")) %>%
    filter(!is.na(category_d_ahead)) %>%
    mutate(category_d_ahead = as.factor(category_d_ahead))

# Reading in feature importances and filtering to only the important ones
feature_importances <- read.csv("data/model_training/feature_importances.csv")
important_features <- feature_importances %>%
    filter(a_n_importance > 0) %>%
    pull("variable")

# Filtering down the total dataset to just the important features and the metadata needed
# for model training. We rename the mcyA_16s column because that was renamed
# after initial model training. If we were to repeat the hyperparameter tuning
# step, we would be able to remove this step.
hab_data <- hab_data_raw %>%
    select(all_of(important_features), category_d_ahead) %>%
    rename(mcya_16s = mcyA_16s)

set.seed(130)
hab_data_split <- initial_split(hab_data, strata = category_d_ahead, prop = 0.8)
hab_train <- training(hab_data_split)
hab_test <- testing(hab_data_split)

######################### Defining tidymodels recipes (data processing steps)
# Defining the base recipe which we'll build off for other workflows.
# We performed all of the preprocessing in the data prep steps of the pipeline
base_recipe <- recipe(formula = category_d_ahead ~ ., data = hab_train)

downsample_recipe <- base_recipe %>%
    step_downsample(category_d_ahead)

oversample_recipe <- base_recipe %>%
    step_smote(category_d_ahead)

# Over/undersampling recipes for no climate data
under_no_climate_rec <- downsample_recipe %>%
    step_rm("avg_dew")

over_no_climate_recipe <- oversample_recipe %>%
    step_rm("avg_dew")

# Over/undersampling recipes for no land_use data
under_no_land_use_rec <- downsample_recipe %>%
    step_rm("hay_pasture", "developed_sum")

over_no_land_use_rec <- oversample_recipe %>%
    step_rm("hay_pasture", "developed_sum")

# Over/undersampling recipes for no climate or climate data
under_no_land_climate_rec <- downsample_recipe %>%
    step_rm("avg_dew", "hay_pasture", "developed_sum")

over_no_land_climate_rec <- oversample_recipe %>%
    step_rm("avg_dew", "hay_pasture", "developed_sum")

all_recipes <- list(
    "under_nc" = under_no_climate_rec,
    "over_nc" = over_no_climate_recipe,
    "under_nl" = under_no_land_use_rec,
    "over_nl" = over_no_land_use_rec,
    "under_nlc" = under_no_land_climate_rec,
    "over_nlc" = over_no_land_climate_rec
)

######################### Defining tidymodels models
# In the model training step, we trained all the models on all of the data using
# under- and oversampling. We then picked the models that performed best on each of
# our performance metrics for further use. The models that performed best were
# the down- and oversampled xgboost models, and the oversampled logistic regression.
# We define the recipes here for later use.

# A generic xgboost model
xgboost_spec <- boost_tree(
    trees = tune(),
    min_n = tune(),
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


######################### Defining workflow sets
# Setting up the folds of the training split for model training.
set.seed(489)
cv_splits <- vfold_cv(hab_train, strata = category_d_ahead, v = 10)

# Setting up control parameters to pass to the workflow_map call just below
race_controls <- control_race(
    parallel_over = "everything",
    save_pred = TRUE,
    save_workflow = TRUE
)

# Defining the tuning combinations to use for hyperparameter tuning, as well as the file name
# to save the tuning results to.
# TODO: Convert tuning_combinations to a Snakemake parameter
tuning_combinations <- 200
workflow_fit_filename <- paste0("variable_importance_workflow_fit_", tuning_combinations, ".rds")

# Here we define the workflow set, filter out the undersampled logistic regressions,
# and tune it all. Since this process can take a while, we check for previously saved hyperparameter tuning runs
# with the same number of tuning combinations. If it hasn't been saved, we'll run the pipeline and save it.
if (!file.exists(here("results/model_training", workflow_fit_filename))) {
    model_fits <- workflow_set(
        preproc = all_recipes,
        models = list(xgboost = xgboost_spec, reg = log_reg_spec)
    ) %>%
        filter(!str_detect(wflow_id, "^under.*reg$")) %>%
        workflow_map(
            "tune_grid",
            resamples = cv_splits,
            grid = tuning_combinations,
            metrics = hab_metrics,
            verbose = TRUE,
            seed = 1834,
            control = race_controls
        )

    saveRDS(
        model_fits,
        here("results/model_training", workflow_fit_filename)
    )
}

model_fits <- readRDS(here("results/model_training", workflow_fit_filename))

# Getting the best models for each model type.
tester <- rank_results(model_fits, rank_metric = "roc_auc", select_best = TRUE) %>%
    select(rank, wflow_id, .metric, mean, std_err, model) %>%
    separate_wider_delim(
        wflow_id,
        delim = "_",
        names = c("sampling_strategy", "vars_removed", "model_type"),
        cols_remove = FALSE
    ) %>%
    mutate(
        sampling_strategy = if_else(
            sampling_strategy == "over",
            "oversampled",
            "undersampled"
        ),
        vars_removed = case_when(
            vars_removed == "nc" ~ "climate",
            vars_removed == "nl" ~ "land_use",
            vars_removed == "nlc" ~ "climate_land_use",
            TRUE ~ vars_removed
        ),
        model_type = if_else(
            model_type == "xgboost",
            "xgboost",
            "log_reg"
        )
    )

######################### Testing results
testing_predictions_df <- hab_test %>%
    select(category_d_ahead)
testing_results_df <- data.frame()

set.seed(4182023)
for (x in model_fits$wflow_id) {
    # This extract the hyperparameters for the model that achieved the best roc auc
    best_model <- model_fits %>%
        extract_workflow_set_result(x) %>%
        select_best(metric = "roc_auc")

    # Finalizes the model with the hyperparameters obtained above
    final_model_fit <- model_fits %>%
        extract_workflow(x) %>%
        finalize_workflow(best_model) %>%
        last_fit(split = hab_data_split, metrics = hab_metrics)

    test_results <- final_model_fit %>%
        collect_metrics()

    # Combine predictions on testing set (with class probabilities) with testing data
    testing_predictions_df <- bind_cols(
        testing_predictions_df,
        final_model_fit %>%
            collect_predictions() %>%
            select(.pred_1, .pred_3, .pred_class) %>%
            setNames(paste0(x, names(.)))
    )

    x <- str_split(x, "_")[[1]]
    this_sampling_strategy <- x[1]
    this_vars_removed <- x[2]
    this_model <- x[3]

    test_results <- test_results %>%
        pivot_wider(names_from = ".metric", values_from = ".estimate") %>%
        mutate(
            vars_removed = this_vars_removed,
            sampling_strategy = this_sampling_strategy,
            model = this_model,
        ) %>%
        select(sampling_strategy, model, sens:roc_auc)


    testing_results_df <- rbind(
        testing_results_df,
        test_results
    )
}

######################### Ensemble metrics
# Here we'll calculate the performance metrics for the hard voting models
# based on which variables were removed

# Defining the different codes for removed variables, instantiating
# the data frame
removed_vars_codes <- c("nc", "nl", "nlc")
ensemble_metrics <- data.frame()

# Loop through the different removed variable codes, calculate the
# hard vote, get the mean class prediction, and calculate the metrics
for (removed_vars in removed_vars_codes) {
    these_predictions <- testing_predictions_df %>%
        select(category_d_ahead, contains(paste0("_", removed_vars, "_"))) %>%
        mutate(
            mean_pred_1 = rowMeans(select(., contains("pred_1")))
        ) %>%
        rowwise() %>%
        mutate(
            hard_vote = getmode(c_across(contains(".pred_class")))
        ) %>%
        ungroup()

    these_metrics <- get_prediction_metrics(these_predictions, category_d_ahead, mean_pred_1, hard_vote) %>%
        pivot_wider(names_from = ".metric", values_from = ".estimate") %>%
        mutate(
            vars_removed = removed_vars,
        ) %>%
        select(vars_removed, roc_auc:spec)

    ensemble_metrics <- rbind(
        ensemble_metrics,
        these_metrics
    )
}

write.csv(
    ensemble_metrics,
    here("results/model_training", "variable_evaluation_metrics.csv"),
    row.names = FALSE,
    quote = FALSE
)
