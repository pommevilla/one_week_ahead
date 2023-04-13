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
        err = "logs/combine_dnr_data.err",
        out = "logs/combine_dnr_data.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule prepare_dnr_data:
    input:
        script = "code/dnr_data/prepare_DNR_data.R",
        dnr_data = "data/dnr_data/dnr_combined.csv"
    output:
        "data/dnr_data/dnr_prepared.csv"
    log:
        err = "logs/prepare_dnr_data.err",
        out = "logs/prepare_dnr_data.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule generate_histograms:
    input:
        script = "code/results_and_figures/generate_histograms.R",
        dnr_data = "data/dnr_data/dnr_combined.csv"
    output:
        "figures/microcystin_histogram.tiff",
        "figures/microcystin_histogram_threshed.tiff"
    log:
        err = "logs/generate_histograms.err",
        out = "logs/generate_histograms.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule generate_historical_hab_plots:
    input:
        script = "code/results_and_figures/generate_historical_hab_plots.R",
        dnr_data = "data/dnr_data/dnr_combined.csv"
    output:
        "figures/historical_hab_occurrences.tiff",
        "figures/historical_hab_occurrences.png"
    log:
        err = "logs/generate_historical_hab_plots.err",
        out = "logs/generate_historical_hab_plots.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """