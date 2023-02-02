# ---------------------------
# Snakemake rules for gathering and preparing weather data
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

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