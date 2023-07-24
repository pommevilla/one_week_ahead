#!/usr/bin/env Rscript
# ---------------------------
# Outputs a formatted gt table of model metrics
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

library(tidyverse)
library(glue)
library(gt)

training_results <- read.csv("data/model_training/training_results_best.csv")
testing_results <- read.csv("data/model_training/testing_results.csv")

##################### Training/testing results

training_results %>%
    mutate(across(mean:std_err, ~ round(., 3))) %>%
    mutate(mean_sd = glue::glue("{mean} ({std_err})")) %>%
    pivot_wider(
        names_from = .metric,
        values_from = mean_sd,
        id_cols = c("wflow_id")
    ) %>%
    select(wflow_id, roc_auc, accuracy, sens, spec) %>%
    write.csv(
        "man.csv",
        row.names = FALSE,
        quote = FALSE
    )

testing_results %>%
    select(model, sampling_strategy, roc_auc, accuracy, sens, spec) %>%
    arrange(model, desc(sampling_strategy))


this_footnote <- md("Scores shown are mean (std. error) of the model parameterization<br/>scoring the highest for that sampling strategy and model.")


training_results %>%
    mutate(across(mean:std_err, ~ round(., 2))) %>%
    mutate(value = glue::glue("{mean} ({std_err})")) %>%
    select(-c(mean, std_err, rank, wflow_id)) %>%
    select(sampling_strategy, everything()) %>%
    mutate(
        sampling_strategy = str_to_title(sampling_strategy),
        model = if_else(
            model == "boost_tree",
            "XGBoost",
            "Logistic Regression"
        )
    ) %>%
    pivot_wider(names_from = ".metric", values_from = "value") %>%
    gt() %>%
    cols_label(
        sampling_strategy = "Sampling Strategy",
        model = "Model",
        accuracy = "Accuracy",
        roc_auc = "ROC AUC",
        sens = "Sensitivity",
        spec = "Specificity"
    ) %>%
    tab_header(
        title = md("Model training metrics")
    ) %>%
    tab_footnote(
        footnote = this_footnote,
    ) %>%
    gtsave("results/model_metrics_table_best.png")
