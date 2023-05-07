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

####
combined_data_set <- combined_data_set %>%
    select(
        -c(week:environmental_location)
    ) %>%
    mutate(category_d = ifelse(category_d_ahead == 1, "Non-hazardous", "Hazardous")) %>%
    mutate(hazard_class = ifelse(category_d_ahead == 1, "Non-hazardous", "Hazardous")) %>%
    mutate(tp = tkp_mg_p_l + ortho_p_mg_p_l)

###### Summary statistics for next week
summary_statistics_next_week <- combined_data_set %>%
    filter(!is.na(hazard_class)) %>%
    tbl_summary(
        by = hazard_class,
        statistic = list(all_continuous() ~ "{mean}")
    ) %>%
    add_p() %>%
    as_tibble() %>%
    filter(`**Characteristic**` != "Unknown")


write.csv(
    summary_statistics_next_week,
    here::here("results", "summary_statistics_one_week_ahead.csv"),
    quote = FALSE,
    row.names = FALSE
)

###### Summary statistics for this week
# Have to read in the original dnr_combined data set because the observations without
# next week's data were removed during data preprocessing
this_week_data <- read.csv("data/dnr_data/dnr_combined.csv") %>%
    select(
        -c(week:environmental_location)
    ) %>%
    mutate(mcya_16s = if_else(!is.finite(mcya_16s), 0, mcya_16s)) %>%
    mutate(category_d = as.factor(if_else(
        microcystin > 8,
        "Hazardous", "Non-hazardous"
    ))) %>%
    mutate(tp = tkp_mg_p_l + ortho_p_mg_p_l)
mutate()

summary_statistics_this_week <- this_week_data %>%
    select(-category_d_ahead) %>%
    tbl_summary(
        by = category_d,
        statistic = list(all_continuous() ~ "{mean}")
    ) %>%
    add_p(
        test = everything() ~ "wilcox.test",
    ) %>%
    as_tibble() %>%
    filter(`**Characteristic**` != "Unknown")


write_delim(
    summary_statistics_this_week,
    here::here("results", "summary_statistics_this_week.tsv"),
    delim = "\t"
)

this_week_data %>%
    mutate(mcya_16s = if_else(!is.finite(mcya_16s), 0, mcya_16s)) %>%
    filter(x16s == 0 & mcy_a_m == 0)
