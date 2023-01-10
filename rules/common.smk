unique_stations = set()

with open("data/stations_nearest_lakes.txt") as fin:
    next(fin)
    for line in fin:
        station = line.strip().split('\t')[1]
        unique_stations.add(station)