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