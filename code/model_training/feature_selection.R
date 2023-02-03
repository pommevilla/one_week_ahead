#!/usr/bin/env Rscript
# ---------------------------
# Performs feature selection.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

######################### Setup
library(tidyverse)
library(rsample)
library(doParallel)
library(glmnet)
library(xgboost)

# Import helper functions and base ggplot theme
source("code/model_training/model_training_helpers.R")

combined_data <- read.csv("data/data_prep/combined_normalized.csv")


######################### Preparing data frame for model training

prepared_data <- combined_data %>%
    select(-c(
        week, collected_date, environmental_location, category_d, microcystin, x16s
    )) %>%
    filter(if_all(everything(), ~ is.finite(.)))

####### Bootstrapping the datasets for feature selection

bootstrapped_samples <- bootstraps(
    prepared_data,
    times = 50,
    apparent = TRUE,
    strata = "category_d_ahead"
)

###### LASSO Importances

cl <- makePSOCKcluster(4)
registerDoParallel(cl)

start_time <- Sys.time()
bootstrapped_samples <- bootstrapped_samples %>%
    mutate(glm.model = map(splits, fit_lasso_on_bootstrap))
end_time <- Sys.time()

stopCluster(cl)

lasso_importances <- get_lasso_importances(bootstrapped_samples)



####### XGBoost Importances

bootstrapped_samples <- bootstrapped_samples %>%
    mutate(xgb.model = map(splits, fit_xgboost_on_bootstrap))

xgb_importances <- get_xgboost_importances(bootstrapped_samples)

####### Combining and normalizing feature importances

# Sometimes XGBoost won't report a feature importance score
# Because of  this, we set the NAs to 0 after joining,
# then calculate normalized scores afterwards.
all_importances <- left_join(
    lasso_importances,
    xgb_importances,
    by = c("variable" = "Feature")
) %>%
    mutate(xgb_importance = if_else(
        is.na(xgb_importance),
        0,
        xgb_importance
    )) %>%
    mutate(n_xgb_importance = scale(xgb_importance))

# Writing out results
write.csv(
    all_importances,
    "data/model_training/feature_importances.csv",
    row.names = FALSE,
    quote = FALSE
)
