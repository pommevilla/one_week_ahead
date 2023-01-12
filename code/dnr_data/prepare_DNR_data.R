#!/usr/bin/env Rscript
# ---------------------------
# Prepares the DNR data for downstream analysis
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
library(here)

dnr_data <- read.csv(here("data", "dnr_combined.csv"))
