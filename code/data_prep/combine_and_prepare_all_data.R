#!/usr/bin/env Rscript
# ---------------------------
# Combines the different data sets into one final table for
# use in model training
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
library(tidyverse)
library(here)

dnr_data <- read.csv("data/dnr_data/dnr_prepared.csv")
weather_data <- read.csv("data/weather/all_stations_weather_imputed.csv")
land_use_data <- read.csv("data/land_use/sample_site_land_use_percentages.csv")

combined <- left_join(
    dnr_data,
    weather_data,
    by = c(
        "environmental_location" = "Location",
        "collected_date" = "Date"
    )
) %>%
    left_join(
        land_use_data,
        by = c("environmental_location" = "sample_site")
    ) %>%
    select(-c(Station))

write.csv(
    combined,
    here("data/data_prep", "combined.csv"),
    row.names = FALSE,
    quote = FALSE
)

# Normalizing data for model training
# mcy_a_a is removed because it mostly contains 0, which leads to NAs after normalization
combined_normalized <- combined %>%
    mutate(across(
        -c(week, collected_date, environmental_location, category_d, category_d_ahead, mcy_a_a),
        ~ (scale(.) %>% as.vector())
    ))

write.csv(
    combined_normalized,
    here("data/data_prep", "combined_normalized.csv"),
    row.names = FALSE,
    quote = FALSE
)
