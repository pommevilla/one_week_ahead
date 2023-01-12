#!/usr/bin/env python
# ---------------------------
# Downloads daily weather data from individual stations
# Inputs:
#   UNIQUE_STATIONS - passed on the command line from snakemake.params
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

import requests
import sys

UNIQUE_STATIONS = sys.argv[1:]


GHCND_URL = "https://www.ncei.noaa.gov/pub/data/ghcn/daily/by_station/{}.csv.gz"
DOWNLOAD_PATH = "data/weather/compressed/{}.csv.gz"

for station in UNIQUE_STATIONS:
    remote_url = GHCND_URL.format(station)
    local_path = DOWNLOAD_PATH.format(station)
    with open(local_path, "wb") as fout:
        r = requests.get(remote_url)
        fout.write(r.content)
