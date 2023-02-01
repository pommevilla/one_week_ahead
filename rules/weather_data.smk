# ---------------------------
# Snakemake rules for gathering and preparing weather data
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

# rule download_weather_data:
#     input:
#         script = "code/weather/get_station_data.py"
#     params:
#         stations = UNIQUE_STATIONS
#     output:
#         COMPRESSED_STATIONS_FILES
#     log:
#         err = "logs/download_weather_data.err",
#         out = "logs/download_weather_data.out"
#     conda:
#         "../environment.yml"
#     threads: 4
#     shell:
#         """
#         {input.script} {params.stations} 2> {log.err} 1> {log.out}
#         """

# rule concatenate_weather_data:
#     input:
#         script = "code/weather/concatenate_weather_files.bash",
#         compressed_files = COMPRESSED_STATIONS_FILES
#     output:
#         "data/weather/all_stations.csv"
#     log:
#         err = "logs/concatenate_weather_stations.err",
#         out = "logs/concatenate_weather_stations.out"
#     conda:
#         "../environment.yml"
#     shell:
#         """
#         {input.script} 2> {log.err} 1> {log.out}
#         """

rule impute_weather:
    input:
        renv_restored = ".hab_prediction_env_restored",
        script = "code/weather/impute_weather_data.R",
        all_stations_data = "data/weather/raw_weather_downloaded.csv"
    output:
        "data/weather/all_stations_weather_imputed.csv"
    log:
        err = "logs/impute_and_prepare_weather.err",
        out = "logs/impute_and_prepare_weather.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """