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
    filter(!is.na(category_d_ahead)) %>%
    select(
        microcystin:mcya_16s,
        category_d_ahead, ortho_p_mg_p_l
    )

summary_statistics <- reduced %>%
    mutate(hazard_class = ifelse(category_d_ahead == 1, "Non-hazardous", "Hazardous")) %>%
    select(-category_d_ahead) %>%
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
