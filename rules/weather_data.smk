# This snakemake file downloads raw weather data
# and prepares it for downstream analysis

rule download_weather_data:
    input:
        script = "code/weather/get_station_data.py"
    params:
        stations = UNIQUE_STATIONS
    output:
        COMPRESSED_STATIONS_FILES
    log:
        err = "logs/download_weather_data.err",
        out = "logs/download_weather_data.out"
    conda:
        "../environment.yml"
    threads: 4
    shell:
        """
        {input.script} {params.stations} 2> {log.err} 1> {log.out}
        """

rule concatenate_weather_data:
    input:
        script = "code/weather/concatenate_weather_files.bash",
        compressed_files = COMPRESSED_STATIONS_FILES
    output:
        "data/weather/all_stations.csv"
    log:
        err = "logs/concatenate_weather_stations.err",
        out = "logs/concatenate_weather_stations.out"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule pivot_and_impute_data:
    input:
        script = "code/weather/prepare_weather_data.R",
        all_stations_data = "data/weather/all_stations.csv"
    output:
        "data/weather/all_stations_prepared.csv"
    log:
        err = "logs/prepare_weather_stations.err",
        out = "logs/prepare_weather_stations.out"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """