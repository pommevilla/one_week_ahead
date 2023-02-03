# ---------------------------
# Snakemake rules for training and evaluating models
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

rule feature_selection:
    input:
        prepared_data = "data/data_prep/combined_normalized.csv",
        script = "code/model_training/feature_selection.R"
    output:
        "data/model_training/feature_importances.csv"
    log:
        err = "logs/feature_selection.err",
        out = "logs/feature_selection.out"
    threads:
        4
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """

rule model_training:
    input:
        prepared_data = "data/data_prep/combined_normalized.csv",
        feature_importances = "data/model_training/feature_importances.csv",
        script = "code/model_training/train_models.R"
    output:
        expand("data/model_training/training_results_{result_type}.csv", result_type=RESULT_TYPES),
        "data/model_training/testing_results.csv"
    log:
        err = "logs/model_training.err",
        out = "logs/model_training.out"
    threads:
        4
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """