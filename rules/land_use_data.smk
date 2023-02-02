# ---------------------------
# Snakemake rules for gathering and preparing land use data
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
rule download_land_use_data:
    input:
        script = "code/land_use/get_land_use_data.sh"
    output:
        "land_use_downloaded.txt"
    log:
        err = "logs/get_land_use_data.err",
        out = "logs/get_land_use_data.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule calculate_land_use_percentages:
    input:
        renvironment_restored = ".hab_prediction_env_restored",
        land_use_downloaded = "land_use_downloaded.txt",
        script = "code/land_use/calculate_sampling_site_land_use.R"
    output:
        "data/land_use/sample_site_land_use_percentages.csv"
    log:
        err = "logs/calculate_land_use_percentages.err",
        out = "logs/calculate_land_use_percentages.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """
