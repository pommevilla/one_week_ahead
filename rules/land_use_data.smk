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

