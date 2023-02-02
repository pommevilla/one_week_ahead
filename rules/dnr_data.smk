# ---------------------------
# Snakemake rules for preparing DNR data
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

rule combine_dnr_data:
    input:
        renv = ".hab_prediction_env_restored",
        script = "code/dnr_data/combine_DNR_data.R"
    output:
        "data/dnr_data/dnr_combined.csv"
    log:
        log = "logs/combine_dnr_data.txt"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log}
        """

rule prepare_dnr_data:
    input:
        script = "code/dnr_data/prepare_DNR_data.R",
        dnr_data = "data/dnr_data/dnr_combined.csv"
    output:
        "data/dnr_data/dnr_prepared.csv"
    log:
        log = "logs/prepare_dnr_data.txt"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log}
        """