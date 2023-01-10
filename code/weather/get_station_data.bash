#!/usr/bin/env bash


# wget -P data/weather/https://www.ncei.noaa.gov/pub/data/ghcn/daily/by_station/$station.csv.gz

stations_nearest_lakes=$1
# station=$1

cut -f2 $1 | while read -r station; do
    wget -P data/weather/ https://www.ncei.noaa.gov/pub/data/ghcn/daily/by_station/$station.csv.gz 
done

# wget -P data/weather/ https://www.ncei.noaa.gov/pub/data/ghcn/daily/by_station/$station.csv.gz 