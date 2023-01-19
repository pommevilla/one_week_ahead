# ---------------------------
# Snakemake rules for training and evaluating models
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------


rule model_training:
    input:
        prepared_data = "data/data_prep/combined.csv",
        renvironment_restored = ".hab_prediction_env_restored",
        script = "code/model_training/train_models.R"
    output:
        expand("data/model_training/training_results_{result_type}.csv", result_type=RESULT_TYPES)
    log:
        err = "logs/model_training.err",
        out = "logs/model_training.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """