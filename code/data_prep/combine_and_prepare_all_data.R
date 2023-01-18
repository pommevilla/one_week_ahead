#!/usr/bin/env Rscript
# ---------------------------
# Combines the different data sets into one final table for
# use in model training
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
library(tidyverse)
library(here)

dnr_data <- read.csv("data/dnr_data/dnr_combined.csv")
closest_stations <- read.delim("data/station_info.txt")
weather_data <- read.csv("data/weather/all_stations_prepared.csv")

combined <- left_join(
    dnr_data, closest_stations,
    by = c("environmental_location" = "Site")
) %>%
    left_join(
        weather_data,
        by = c("Station" = "STATION", "collected_date" = "DATE")
    )

write.csv(
    combined,
    here("data/data_prep", "combined.csv"),
    row.names = FALSE,
    quote = FALSE
)
