# ---------------------------
# Snakemake rules for preparing the combined dataset
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

rule combine_and_prepare_data_sets:
    input:
        weather_data = "data/weather/all_stations_weather_imputed.csv",
        dnr_data = "data/dnr_data/dnr_combined.csv",
        closest_stations = "data/station_info.txt",
        land_use_data = "data/land_use/sample_site_land_use_percentages.csv",
        script = "code/data_prep/combine_and_prepare_all_data.R",
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