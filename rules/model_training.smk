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
        # Figures
        # Tables
        touch(".model_training_complete")
    log:
        err = "logs/model_training.err",
        out = "logs/model_training.out"
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """