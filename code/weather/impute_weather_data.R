#!/usr/bin/env Rscript
# ---------------------------
# Prepare weather station data for downstream data analysis by
# imputing missing data
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

library(tidyverse)
library(lubridate)

# These are the months and years the study was performed
all_weather_data <- read.csv("data/weather/raw_weather_downloaded.csv")

# Just bad for now
all_weather_imputed <- all_weather_data %>%
    group_by(Station, month(Date)) %>%
    mutate(across(
        avg_temp:precip,
        ~ ifelse(is.na(.), mean(., na.rm = TRUE), .)
    )) %>%
    ungroup() %>%
    group_by(Station) %>%
    mutate(across(
        avg_temp:precip,
        ~ ifelse(is.na(.), mean(., na.rm = TRUE), .)
    )) %>%
    ungroup()

write.csv(
    all_weather_imputed,
    "data/weather/all_stations_weather_imputed.csv",
    row.names = FALSE,
    quote = FALSE
)
