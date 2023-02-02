#!/usr/bin/env Rscript
# ---------------------------
# Parses the land use layer from MRLC to get the land use proportions
# within 1km of each sampling site.
# Note that the input file, iowa_mrlc_land_use, is a reduced full CONUS 2019 MRLC data,
# available from https://www.mrlc.gov/data/nlcd-2019-land-cover-conus
# This is because the full dataset is 2.8 GB zipped.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
library(raster)
library(tidyverse)
library(sf)
library(here)

land_use_directory <- "data/land_use/MRLC_Iowa_2019"
iowa_crs <- 26976

# This is the County boundaries of Iowa
iowa_sf <- read_sf("data/shapefiles/Iowa_County_Boundaries/")

# This is the raster containg land use classifications according to the 2019 report from
# the Multi-Resolution Landuse Consortium (https://www.mrlc.gov/data/nlcd-2019-land-cover-conus)
iowa_land_use <- raster(here(
    land_use_directory,
    "NLCD_2019_Land_Cover_L48_20210604.tiff"
))

# This is the legend that corresponds to the categories in iowa_land_use
land_use_categories <- read.csv(
    here(land_use_directory, "NLCD_landcover_legend_2018_12_17.csv"),
    col.names = c("value", "category")
) %>%
    filter(category != "") %>%
    mutate(join_col = paste0("frac_", value))

# These are the coordinates of the sampling site locations
sample_site_locations <- read.delim("data/station_info.txt") %>%
    select(Site, site_longitude, site_latitude) %>%
    st_as_sf(coords = c("site_longitude", "site_latitude"), crs = 4326) %>%
    st_transform(crs = iowa_crs)


# Create the 1km radius around the sampling point
sample_site_buffers <- st_buffer(sample_site_locations, dist = 1000)

# Calculates the proportion of each land use category in a 1km radius around each sample location
land_use_props <- exactextractr:::exact_extract(
    iowa_land_use,
    sample_site_buffers,
    fun = "frac"
) %>%
    mutate(across(everything(), ~ round(., digits = 2)))

# Renames the columns of the land use proportions using land_use_categories
names(land_use_props) <- land_use_categories$category[match(names(land_use_props), land_use_categories$join_col)]

# We can use the Site names from sample_site_buffers since the rows are in the same order
# as the rows of land_use_props
# We also combine similar classifications into broader categories; ie, land classified as
# some degree of developed, forest, or wetlands
land_use_props <- land_use_props %>%
    janitor::clean_names() %>%
    mutate(sample_site = sample_site_buffers$Site) %>%
    select(sample_site, everything()) %>%
    mutate(wetlands_sum = rowSums(across(contains("wetlands"))), .keep = "unused") %>%
    mutate(developed_sum = rowSums(across(contains("developed"))), .keep = "unused") %>%
    mutate(forest_sum = rowSums(across(contains("forest"))), .keep = "unused")

write.csv(
    land_use_props,
    "data/land_use/sample_site_land_use_percentages.csv",
    row.names = FALSE,
    quote = FALSE
)
