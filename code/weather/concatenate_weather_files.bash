#!/usr/bin/env bash

for station_data in data/weather/compressed/US*csv.gz;
do
    echo "found $station_data"
    gunzip -c $station_data | grep "ADPT\|AWND\|EVAP" >> data/weather/all_stations.csv
done
    