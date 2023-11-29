tester_wf <- extract_workflow_set_result(hab_models_1, "downsampled_xgboost")

tester <- extract_parameter_set_dials(hab_models_1, "downsampled_xgboost")

tester$parameters

extract_parameter_set_dials(hab_models_1, "downsampled_xgboost")

parameters(tester)

# Extract tuned parameter values from hab_models_1
tester <- extract_parameter_set_dials(hab_models_1, "downsampled_xgboost")

# Get actual parameters values from the workflow
parameters(tester)



for (wf_name in hab_models_1$wflow_id) {
    # print(paste("Looking at", wf_name))
    this_wf <- extract_workflow_set_result(hab_models_1, wf_name)
    best_params <- this_wf %>%
        select_best("roc_auc") %>%
        mutate(wflow_id = wf_name) %>%
        separate("wflow_id", c("wflow_id", "sampling_strategy"))

    print(best_params)
}
