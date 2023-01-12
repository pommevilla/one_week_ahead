#!/usr/bin/env bash
# ---------------------------
# Script name: concatenate_weather_files.bash
# Purpose: Concatenate the individual weather files into a single collected file,
# filtering the rows for our variables of interest while doing so.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

# See section III of https://www.ncei.noaa.gov/pub/data/ghcn/daily/readme.txt for details
VARIABLES_OF_INTEREST="ADPT\|AWND\|EVAP\|PRCP\|TAVG"

for station_data in data/weather/compressed/US*csv.gz;
do
    gunzip -c $station_data | grep $VARIABLES_OF_INTEREST >> data/weather/all_stations.csv
done
    