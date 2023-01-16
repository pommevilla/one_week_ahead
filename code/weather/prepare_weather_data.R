#!/usr/bin/env Rscript
# ---------------------------
# Prepare weather station data for downstream data analysis by
# filtering the data down to the relevant years, pivoting the table,
# imputing missing data, then calculating a 5-day average of each variable.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

library(tidyverse)
library(lubridate)

# These are the months and years the study was performed
months_of_study <- seq(5, 10)
years_of_study <- seq(2018, 2021)

all_data <- read.csv("data/weather/all_stations.csv",
    header = FALSE
) %>%
    select(
        STATION = 1,
        DATE = 2,
        ELEMENT = 3,
        MEASUREMENT = 4
    ) %>%
    mutate(DATE = ymd(DATE)) %>%
    filter(year(DATE) %in% years_of_study) %>%
    filter(month(DATE) %in% months_of_study) %>%
    pivot_wider(names_from = ELEMENT, values_from = MEASUREMENT)


write.csv(all_data, "data/weather/all_stations_prepared.csv", row.names = FALSE, quote = FALSE)
