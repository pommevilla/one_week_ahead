#!/usr/bin/env Rscript
# ---------------------------
# Prepares the DNR data for downstream analysis
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
library(here)
library(lubridate)
library(tidyverse)

dnr_data <- read.csv(
    here("data/dnr_data", "dnr_combined.csv")
)

# Imputing missing values for chemical measurements based on month and sample location
# NA values are replaced by the mean of the month and sample location, while infinite values
# are replaced by the max of the month and sample location
dnr_imputed <- dnr_data %>%
    group_by(environmental_location, month(collected_date)) %>%
    mutate(across(
        c(doc_ppm:mcya_16s, ortho_p_mg_p_l),
        ~ ifelse(is.infinite(.), NA, .)
    )) %>%
    mutate(across(
        c(doc_ppm:mcya_16s, ortho_p_mg_p_l),
        ~ ifelse(is.infinite(.), max(., na.rm = TRUE), .)
    )) %>%
    mutate(across(
        c(doc_ppm:mcya_16s, ortho_p_mg_p_l),
        ~ ifelse(is.na(.), mean(., na.rm = TRUE), .)
    )) %>%
    ungroup(`month(collected_date)`) %>%
    mutate(across(
        c(doc_ppm:mcya_16s, ortho_p_mg_p_l),
        ~ ifelse(is.infinite(.), NA, .)
    )) %>%
    mutate(across(
        c(doc_ppm:mcya_16s, ortho_p_mg_p_l),
        ~ ifelse(is.infinite(.), max(., na.rm = TRUE), .)
    )) %>%
    mutate(across(
        c(doc_ppm:mcya_16s, ortho_p_mg_p_l),
        ~ ifelse(is.na(.), mean(., na.rm = TRUE), .)
    )) %>%
    ungroup()

write.csv(
    dnr_imputed,
    here("data/dnr_data", "dnr_prepared.csv"),
    row.names = FALSE,
    quote = FALSE
)
