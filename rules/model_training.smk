# ---------------------------
# Snakemake rules for training and evaluating models
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

# Narrows down the full feature set to those that are most important.
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

# Trains the models and evaluate their performance. We use a logistic regression,
# a neural network, and an XGBoost model, as well as under- and oversampling.
rule model_training:
    input:
        prepared_data = "data/data_prep/combined_normalized.csv",
        feature_importances = "data/model_training/feature_importances.csv",
        script = "code/model_training/train_models.R"
    output:
        expand("data/model_training/training_results_{result_type}.csv", result_type=RESULT_TYPES),
        "data/model_training/testing_results.csv",
        "results/model_training/ensemble_model_prio_roc_auc.rds",
        "results/model_training/hab_models_1_200.rds"
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

# Evaluates how the inclusion/exclusion of different variables
# affects model performance. We hypothesize that the inclusion of
# both land use and climate variables improves model performance,
# which we evaluate here by including/excluding each variable type.
# The results of including both variable types have already been recording in 
# the model_training rule, so we only need to evaluate the cases where 
# land use, climate, or both are excluded.
rule evaluate_variable_contributions:
    input:
        prepared_data = "data/data_prep/combined_normalized.csv",
        feature_importances = "data/model_training/feature_importances.csv",
        script = "code/model_training/land_use_climate_data_comparison.R"
    output:
        "results/model_training/variable_evaluation_metrics.csv",
        "results/model_training/variable_importance_workflow_fit_200.rds"
    log:
        err = "logs/evaluate_variables.err",
        out = "logs/evaluate_variables.out"
    threads:
        4
    conda:
        "../environment.yml"
    shell:
        """
        {input.script} 2> {log.err} 1> {log.out}
        """