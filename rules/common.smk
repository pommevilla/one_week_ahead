# This sucks. I'd rather define them programatically via parsing data/stations_nearest_lakes.txt,
# but since that would run on every pipeline run, Snakemake thinks that UNIQUE_STATIONS has changed
# between runs, forcing the download of all of the compressed files again. Defining the stations this
# way prevents that from happening.
UNIQUE_STATIONS = [
    "US1IACS0002", "US1IADV0002", "US1IAHD0005", "US1IAJH0001",
    "US1IALN0024", "US1IAMN0002", "US1IAPK0021", "US1IAPT0013",
    "US1IASH0003", "US1IAUN0001", "US1IAWR0007", "USC00130576",
    "USC00131394", "USC00133120", "USC00133473", "USC00133509",
    "USC00133584", "USC00134389", "USC00135493", "USC00136327",
    "USC00136910", "USC00136940", "USC00137161", "USC00137312",
    "USC00137859", "USC00138009", "USC00138688", "USC00138808",
    "USW00014940", "USW00094910", "USW00094991",
]

COMPRESSED_STATIONS_FILES = expand("data/weather/compressed/{station}.csv.gz", station=UNIQUE_STATIONS)

RESULT_TYPES = ["all", "best"]

FEATURE_TYPES = ["all", "ani", "lasso", "xgb"]