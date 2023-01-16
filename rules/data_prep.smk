# ---------------------------
# Snakemake rules for preparing the combined dataset
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

rule combine_and_prepare_data_sets:
    input:
        weather_data = "data/weather/all_stations_prepared.csv",
        dnr_data = "data/dnr_data/dnr_combined.csv",
        closest_stations = "data/stations_nearest_lakes.txt",
        script = "code/data_prep/combine_and_prepare_all_data.R"
    output:
        "data/data_prep/combined.csv"
    log:
        err = "logs/combine_all_data_sets.err",
        out = "logs/combine_all_data_sets.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """