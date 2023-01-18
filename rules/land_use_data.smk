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

# rule process_mrlc_layer:
#     input:
#         mrlc_layer = "data/land_use/",
#         script = "code/land_use/process_mrlc_layer.R"
#     output:
#         "data/land_use/land_use_percentages.csv"
#     log:
#         err = "logs/process_mrlc_layer.err",
#         out = "logs/process_mrlc_layer.out"
#     conda:
#         "../environment.yml"
#     shell:
#         """
#         {input.script} 2> {log.err} 1> {log.out}
#         """
