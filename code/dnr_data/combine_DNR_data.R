#!/usr/bin/env Rscript

library(tidyverse)
library(janitor)
library(readxl)
library(here)
library(lubridate)
# library(sf)
library(stringr)


iowa_crs <- 26976

dnr_2018 <- read_xlsx(here("data/dnr_data", "IowaDNR_2018_Data_Merged.xlsx"), sheet = "Sheet2") %>%
  clean_names() %>%
  separate(sample_id, c("week", NA), "-") %>%
  rename(microcystin = 6, x16s = 16, mcy_a_m = 17, mcy_a_a = 18, mcy_a_p = 19) %>%
  select(1:19) %>%
  select(-c(4, 5)) %>%
  mutate(across(c(nh3_mg_n_l, no2_mg_n_l, cl_mg_cl_l, so4_mg_so4_l), as.numeric)) %>%
  mutate(
    tn = tkn_mg_n_l + n_ox_mg_n_l,
    tn_tp_2 = tn / tkp_mg_p_l,
    collected_date = lubridate::date(collected_date),
    mcya_16s = mcy_a_m / x16s
  ) %>%
  mutate(
    category_d = as.factor(if_else(microcystin < 8, 1, 3))
  ) %>%
  group_by(environmental_location) %>%
  mutate(
    category_d_ahead = lead(category_d, 1),
  ) %>%
  ungroup()


# Iowa DNR lake readings
dnr_2019 <- read_xlsx(here("data/dnr_data", "IowaDNR_2019_Data_Merged.xlsx"), sheet = "combined") %>%
  separate(Label, c("week", NA), "-") %>%
  clean_names() %>%
  filter(environmental_location != "Bob White Beach") %>%
  mutate(
    tn = tkn_mg_n_l + n_ox_mg_n_l,
    tp = tkp_mg_p_l + ortho_p_mg_p_l,
    tn_tp = tn / tp,
    tn_tp_2 = tn / tkp_mg_p_l,
    mcya_16s = mcy_a_m / x16s,
    collected_date = lubridate::date(collected_date)
  ) %>%
  mutate(
    category_d = as.factor(if_else(microcystin < 8, 1, 3))
  ) %>%
  group_by(environmental_location) %>%
  mutate(
    category_d_ahead = lead(category_d, 1),
    microcystin_ahead = lead(microcystin, n = 1)
  ) %>%
  ungroup()

dnr_2020 <- read_xlsx(here("data/dnr_data", "IowaDNR_2020_Data_Merged.xlsx"), sheet = "Sheet1") %>%
  separate(Label, c("week", NA), "-") %>%
  clean_names() %>%
  filter(environmental_location != "Bob White Beach") %>%
  mutate(across(c(mcy_a_a:cl_mg_cl_l), as.numeric),
    collected_date = lubridate::date(collected_date)
  ) %>%
  mutate(
    tp = tkp_mg_p_l + ortho_p_mg_p_l,
    mcya_16s = mcy_a_m / x16s
  ) %>%
  mutate(
    category_d = as.factor(if_else(microcystin < 8, 1, 3))
  ) %>%
  group_by(environmental_location) %>%
  mutate(
    category_d_ahead = lead(category_d, 1),
    microcystin_ahead = lead(microcystin, n = 1)
  ) %>%
  ungroup() %>%
  dplyr::select(-c(isu_number, new_id))

dnr_2021 <- read_xlsx(here("data/dnr_data", "IowaDNR_2021_Data_Merged.xlsx")) %>%
  clean_names() %>%
  select(-c(client_reference, ortho_p, dissolved_oxygen_mg_l)) %>%
  separate(label, c("week", NA), "_") %>%
  mutate(p_h = as.numeric(p_h)) %>%
  rename(
    mcy_a_p = ap,
    mcy_a_a = aa,
    mcy_a_m = am
  ) %>%
  mutate(
    mcya_16s = mcy_a_m / x16s
  ) %>%
  mutate(
    category_d = as.factor(if_else(microcystin < 8, 1, 3))
  ) %>%
  group_by(environmental_location) %>%
  mutate(
    category_d_ahead = lead(category_d, 1),
    collected_date = lubridate::date(collected_date)
  ) %>%
  ungroup()

common_columns <- intersect(
  names(dnr_2019),
  intersect(
    names(dnr_2020),
    names(dnr_2018)
  )
)

# Weather data
# schuyler_data <- readRDS("../data/weather_imputed.RDS")

# seven_dra <- schuyler_data %>%
#   as_tibble() %>%
#   select(Location:Date, contains("avg"), precip) %>%
#   mutate(across(contains("avg"), ~ rollmean(., 7, fill = NA, align = "left"))) %>%
#   mutate(Location = case_when(
#     str_detect(Location, "Beed") ~ "Beed's Lake Beach",
#     str_detect(Location, "Crandall") ~ "Crandall's Beach",
#     str_detect(Location, "Pleasant Creek Lake Beach") ~ "Pleasant Creek",
#     # str_detect(Location, "Union Grove") ~ "Union Grove Beach",
#     str_detect(Location, "Pike") ~ "Pike's Point Beach",
#     TRUE ~ Location
#   ))


dnr_all <- bind_rows(dnr_2018, dnr_2019, dnr_2020, dnr_2021) %>%
  dplyr::select(all_of(common_columns), ortho_p_mg_p_l) %>%
  mutate(
    environmental_location = case_when(
      str_detect(environmental_location, "Union Grove") ~ "Union Grove Beach",
      TRUE ~ environmental_location
    )
  ) %>%
  filter(!is.na(collected_date))

write.csv(dnr_all, here("data/dnr_data", "dnr_combined.csv"), row.names = FALSE, quote = FALSE)
