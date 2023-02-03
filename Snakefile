include: "rules/common.smk"

rule targets:
    input:
        "figures/snakemake_dag.png",
        "data/dnr_data/dnr_combined.csv",
        "data/weather/all_stations_weather_imputed.csv",
        "data/data_prep/combined.csv",
        "data/data_prep/combined_normalized.csv",
        "data/model_training/feature_importances.csv",
        expand("data/model_training/training_results_{result_type}.csv", result_type=RESULT_TYPES),
        "data/land_use/sample_site_land_use_percentages.csv",
        expand("figures/training_metrics_{result_type}.png", result_type=RESULT_TYPES),
        "results/summary_statistics_one_week_ahead.csv"

rule restore_renv:
    input:
        r_script = "code/restore_renv.R",
        r_depends_file = "DESCRIPTION"
    output:
        touch(".hab_prediction_env_restored")
    log:
        err = "logs/restore_r.err",
        out = "logs/restore_r.out"
    conda:
        "environment.yml"
    shell:
        """
        {input.r_script} 2> {log.err} 1> {log.out}
        """

rule generate_snakemake_dag:
    input:
        script = "code/make_snakemake_dag.sh",
    output:
        "figures/snakemake_dag.png",
    log:
        log = "logs/generate_snakemake_dag.txt"
    conda:
        "environment.yml"
    shell:
        """
        {input.script} 2> {log}
        """

include: "rules/weather_data.smk"
include: "rules/dnr_data.smk"
include: "rules/land_use_data.smk"
include: "rules/data_prep.smk"
include: "rules/model_training.smk"
include: "rules/results_and_figures.smk"
