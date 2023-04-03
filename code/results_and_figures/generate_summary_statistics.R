#!/usr/bin/env Rscript
# ---------------------------
# Outputs summary statistics of chemical measurements of
# combined dataset
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

library(tidyverse)
library(gt)
library(gtsummary)

combined_data_set <- read.csv("data/data_prep/combined.csv")

reduced <- combined_data_set %>%
    select(
        -c(week:environmental_location)
    ) %>%
    mutate(hazard_class = ifelse(category_d_ahead == 1, "Non-hazardous", "Hazardous")) %>%
    select(-category_d_ahead) %>%
    filter(!is.na(hazard_class)) %>%
    mutate(tp = tkn_mg_n_l + ortho_p_mg_p_l)


summary_statistics <- reduced %>%
    tbl_summary(
        by = hazard_class,
        statistic = list(all_continuous() ~ "{mean}")
    ) %>%
    add_p() %>%
    as_tibble() %>%
    filter(`**Characteristic**` != "Unknown")


write.csv(
    summary_statistics,
    here::here("results", "summary_statistics_one_week_ahead.csv"),
    quote = FALSE,
    row.names = FALSE
)
