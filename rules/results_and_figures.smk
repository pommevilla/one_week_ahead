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

rule generate_summary_statistics:
    input:
        renvironment_restored = ".hab_prediction_env_restored",
        combined_data = "data/data_prep/combined.csv",
        script = "code/results_and_figures/generate_summary_statistics.R"
    output:
        "results/summary_statistics_one_week_ahead.csv"
    log:
        err = "logs/generate_summary_statistics.err",
        out = "logs/generate_summary_statistics.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule generate_feature_importance_plots:
    input:
        feature_importances = "data/model_training/feature_importances.csv",
        script = "code/results_and_figures/generate_feature_importance_plots.R"
    output:
        expand(
            "figures/feature_importance/{feature_type}_importances.png", 
            feature_type=FEATURE_TYPES
        )
    log:
        err = "logs/generate_feature_importance_plots.err",
        out = "logs/generate_feature_importance_plots.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """