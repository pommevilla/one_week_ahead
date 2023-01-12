UNIQUE_STATIONS = set()

with open("data/stations_nearest_lakes.txt") as fin:
    next(fin)
    for line in fin:
        station = line.strip().split('\t')[1]
        UNIQUE_STATIONS.add(station)

COMPRESSED_STATIONS_FILES = expand("data/weather/compressed/{station}.csv.gz", station=UNIQUE_STATIONS)