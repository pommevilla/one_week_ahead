# ---------------------------
# Snakemake rules for generating results and figures
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
# rule generate_best_model_metrics_table:
#     input:
#         script = "code/results_and_figures/generate_model_metrics_table.R",
#         model_metrics = "data/model_training/training_results_best.csv"
#     output:
#         "results/model_metrics_table_best.png"
#     log:
#         err = "logs/generate_model_metrics_table.err",
#         out = "logs/generate_model_metrics_table.out"
#     conda:
#         "../environment.yml"
#     shell:
#         """
#         {input.script} 2> {log.err} 1> {log.out}
#         """

rule generate_model_metrics_figures:
    input:
        script = "code/results_and_figures/generate_model_metrics_plots.R",
        model_metrics = expand(
            "data/model_training/training_results_{result_type}.csv", 
            result_type=RESULT_TYPES
        )
    output:
        expand("figures/training_metrics_{result_type}.png", result_type=RESULT_TYPES)
    log:
        err = "logs/generate_model_metrics_plots.err",
        out = "logs/generate_model_metrics_plots.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """
