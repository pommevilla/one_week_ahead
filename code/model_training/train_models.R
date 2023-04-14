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

# Reading in feature importances
feature_importances <- read.csv("data/model_training/feature_importances.csv")

# We say a feature is important if it's average normalized importance
# was greater than 0. This indicates that its predictive power was greater than average
# according to our resampling framework.
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

# Defining under- and oversampling recipes. Since we have such a small number of
# hazardous cases, we want to try both sampling strategies to see which one
# is better for model performance.
downsample_recipe <- base_recipe %>%
    step_downsample(category_d_ahead)

oversample_recipe <- base_recipe %>%
    step_smote(category_d_ahead)

######################### Defining tidymodels models
# Defining the XGBoost model and setting the parameters that we'll tune.
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

# Defining neural network model
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

# Setting up the folds of the training split for model training.
set.seed(489)
cv_splits <- vfold_cv(hab_train, strata = category_d_ahead, v = 10)

# Setting up control parameters to pass to the workflow_map call just below
race_controls <- control_race(
    parallel_over = "everything",
    save_pred = TRUE,
    save_workflow = TRUE
)

# Model training. This will perform vfold cross-validation for each model configuration and
# sampling strategy defined above. The grid parameter controls how many different
# hyperparameter combinations will be tested for each model.
tuning_combinations <- 200
workflow_fit_filename <- paste0("hab_models_1_", tuning_combinations, ".rds")

# Since this process can take a while, we check for previously saved hyperparameter tuning runs
# with the same number of tuning combinations. If it hasn't been saved, we'll run the pipeline and save it.
if (!file.exists(here("results/model_training", workflow_fit_filename))) {
    hab_models_1 <- workflow_set(
        preproc = list(downsampled = downsample_recipe, oversampled = oversample_recipe),
        models = list(xgboost = xgboost_spec, log_reg = log_reg_spec, nn = nn_spec),
        cross = TRUE
    ) %>%
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
        hab_models_1,
        here("results/model_training", workflow_fit_filename)
    )
}

# This loads the result of the hyperparameter tuning (based on the number of hyperparameter
# combinations defined above)
hab_models_1 <- readRDS(here("results/model_training", workflow_fit_filename))

######## Naive model calculations
# Our naive model predicts the next week's status to be whatever the
# current week's status is. We calculate the confusion matric
# and the ROC AUC here for later use. We'll calculate the other metrics
# below.
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

######### Training Results
# These are the results from model training with an additional row
# for the metrics from the naive model. Note that even though we are mostly
# interested in the performance of the model when predicting the negative class,
# we use ROC AUC because it is a better overall indicator of model performance, especially
# when there are real-world economic costs to closing a beach due to a predicted HAB.
all_results <- rank_results(hab_models_1, rank_metric = "roc_auc") %>%
    select(rank, wflow_id, .metric, mean, std_err, model) %>%
    mutate(sampling_strategy = str_split(wflow_id, "_", simplify = TRUE)[, 1]) %>%
    add_naive_results(confusion_table, naive_auc)

# Record all of the training results to a csv
write.csv(
    all_results,
    here("data/model_training", "training_results_all.csv"),
    row.names = FALSE,
    quote = FALSE
)

# Training metrics again, but only selecting the best performing model from each
# model and preprocessing type.
best_results <- rank_results(hab_models_1, select_best = TRUE, rank_metric = "roc_auc") %>%
    select(rank, wflow_id, .metric, mean, std_err, model) %>%
    mutate(sampling_strategy = str_split(wflow_id, "_", simplify = TRUE)[, 1]) %>%
    add_naive_results(confusion_table, naive_auc)

best_results %>%
    select(-std_err) %>%
    pivot_wider(values_from = mean, names_from = .metric) %>%
    view()


# Write out best model performance to a csv
write.csv(
    best_results,
    here("data/model_training", "training_results_best.csv"),
    row.names = FALSE,
    quote = FALSE
)

######### Creating an ensemble model
# We'll explore various strategies for combing models to improve predictions.
# We'll begin by picking the model that performs best for each of the metrics.
best_models_by_metric <- best_results %>%
    filter(model != "naive") %>%
    group_by(.metric) %>%
    slice_max(mean, n = 1) %>%
    ungroup()

# We'll begin by blending predictions. We prioritize ROC AUC for the same above reasons.
set.seed(1736)
ensemble_model <- stacks() %>%
    add_candidates(
        hab_models_1 %>%
            filter(wflow_id %in% unique(best_models_by_metric$wflow_id))
    ) %>%
    blend_predictions(
        metric = metric_set(roc_auc)
    ) %>%
    fit_members()

saveRDS(
    ensemble_model,
    here("results/model_training", "ensemble_model_prio_roc_auc.rds")
)

# Generating predictions from the ensemble model, including class probabilities
ensemble_predictions <- hab_test %>%
    bind_cols(predict(ensemble_model, hab_test, type = "prob")) %>%
    mutate(predicted = as.factor(if_else(.pred_1 > 0.5, 1, 3)))

# Get metrics from ensemble predictions on the testing set.
ensemble_confusion_matrix <- table(
    ensemble_predictions[, "category_d_ahead"],
    ensemble_predictions[, "predicted"]
)

ensemble_confusion_matrix

get_prediction_metrics(ensemble_predictions, category_d_ahead, .pred_1, predicted)

################## Testing results
# We'll only evaluate the testing results of the best model for each configuration.
# These steps will redefine the models with the highest-performing hyperparameters,
# fit it again on the training data, and then generate predictions on the testing set.
testing_predictions_df <- hab_test %>%
    select(category_d_ahead)
testing_results_df <- data.frame()

for (x in hab_models_1$wflow_id) {
    # This extract the hyperparameters for the model that achieved the best roc auc
    best_model <- hab_models_1 %>%
        extract_workflow_set_result(x) %>%
        select_best(metric = "roc_auc")

    # Finalizes the model with the hyperparameters obtained above
    final_model_fit <- hab_models_1 %>%
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

# Adding results for the naive prediction strategy.
testing_results <- testing_results_df %>%
    add_row(
        sampling_strategy = "naive",
        model = "naive",
        sens = calc_sensitivity(confusion_table),
        spec = calc_specificity(confusion_table),
        accuracy = calc_accuracy(confusion_table),
        roc_auc = naive_auc
    )

# Best models by testing performance
testing_results %>%
    filter(model != "naive") %>%
    pivot_longer(
        cols = sens:roc_auc,
        names_to = "metric",
        values_to = "value"
    ) %>%
    group_by(metric) %>%
    slice_max(value, n = 1)

# Wide format testing results
testing_results %>%
    select(model, sampling_strategy, roc_auc, accuracy, sens, spec) %>%
    arrange(desc(model), desc(sampling_strategy))

# We save the results in long format for easier plotting.
write.csv(
    testing_results,
    here("data/model_training", "testing_results.csv"),
    row.names = FALSE,
    quote = FALSE
)

######## Manual ensemble
# Here, we'll pick the models that performed the best for each of the metrics
# and use them to generate hard and soft predictions.
voting_predictions <- testing_predictions_df %>%
    select(
        category_d_ahead,
        contains("downsampled_xgboost"),
        contains("oversampled_xgboost"),
        contains("oversampled_log_reg")
    ) %>%
    mutate(
        mean_pred_1 = rowMeans(select(., contains(".pred_1"))),
        mean_prediction = as.factor(if_else(mean_pred_1 > 0.5, 1, 3))
    )

# This generates the metrics for the soft predictions
get_prediction_metrics(voting_predictions, category_d_ahead, mean_pred_1, mean_prediction)

mode_predictions <- voting_predictions %>%
    rowwise() %>%
    mutate(mode = getmode(c_across(contains(".pred_class")))) %>%
    ungroup()

# This generates the metrics for the hard predictions
get_prediction_metrics(mode_predictions, category_d_ahead, mean_pred_1, mode)
