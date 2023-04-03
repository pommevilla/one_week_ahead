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
set.seed(1852)
bootstrapped_samples <- bootstraps(
    prepared_data,
    times = 1000,
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
    mutate(n_xgb_importance = scale(xgb_importance)) %>%
    mutate(nice_name = case_when(
        variable == "mcy_a_m" ~ "mcyA M",
        variable == "mcy_a_p" ~ "mcyA P",
        variable == "mcy_a_a" ~ "mcyA A",
        variable == "doc_ppm" ~ "DOC",
        variable == "tkp_mg_p_l" ~ "TKP",
        variable == "tkn_mg_n_l" ~ "TKN",
        variable == "cl_mg_cl_l" ~ "CL",
        variable == "p_h" ~ "pH",
        variable == "mcya_16s" ~ "McyA M:16s",
        variable == "ortho_p_mg_p_l" ~ "Ortho-P",
        variable == "avg_temp" ~ "Avg. Weekly Temperature",
        variable == "avg_humid" ~ "Avg. Humidity",
        variable == "avg_dew" ~ "Avg. Dew Point Temperature",
        variable == "avg_wind" ~ "Avg. Wind speed",
        variable == "avg_gust" ~ "Avg. Gust Speed",
        variable == "precip" ~ "Avg. Weekly Precipitation",
        variable == "open_water" ~ "% Open Water",
        variable == "barren_land" ~ "% Barren Land",
        variable == "shrub_scrub" ~ "% Shrubbery/Scrubland",
        variable == "herbaceuous" ~ "% Herbaceuous Land",
        variable == "hay_pasture" ~ "% Hay/Pasture",
        variable == "cultivated_crops" ~ "% Cultivated Crops",
        variable == "wetlands_sum" ~ "% Wetlands",
        variable == "developed_sum" ~ "% Developed",
        variable == "forest_sum" ~ "% Forested",
        TRUE ~ NA
    )) %>%
    mutate(
        a_n_importance = rowMeans(select(., starts_with("n_")))
    )

# Writing out results
write.csv(
    all_importances,
    "data/model_training/feature_importances.csv",
    row.names = FALSE,
    quote = FALSE
)
