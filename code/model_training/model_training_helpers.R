# ---------------------------
# Various functions to help with the model training process
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

########## LASSO functions

# Passed to purrr::map to fit a lasso model on bootstrap splits
fit_lasso_on_bootstrap <- function(split) {
    df <- analysis(split)
    x <- df %>%
        select(-category_d_ahead) %>%
        as.matrix()
    y <- df %>%
        select(category_d_ahead) %>%
        as.matrix()
    cv.glmnet(
        x, y,
        alpha = 0.5,
        family = "binomial",
        parallel = TRUE
    )
}
# Once the above function is completed, this function will get all of the feature importance
# scores and average them all together
get_lasso_importances <- function(boot_splits) {
    boot_splits %>%
        select(glm.model) %>%
        transmute(var_imp = map(glm.model, coef)) %>%
        pluck("var_imp") %>%
        lapply(as.matrix) %>%
        reduce(`+`) %>%
        as.data.frame() %>%
        transmute(lasso_importance = abs(s1 / dim(boot_splits)[1])) %>%
        rownames_to_column(var = "variable") %>%
        filter(variable != "(Intercept)") %>%
        mutate(n_lasso_importance = scale(lasso_importance))
}


########## XGBoost functions
# Same functions as for the LASSO training except we need an additional
# helper function to tidy up data preparation
prep_data_for_xgb <- function(split_data) {
    x_data <- split_data %>%
        select(-c(category_d_ahead)) %>%
        data.matrix()
    x_labels <- split_data %>%
        select(category_d_ahead) %>%
        mutate(category_d_ahead = if_else(category_d_ahead == 1, 0, 1)) %>%
        data.matrix()

    data_sets <- list(data = x_data, labels = x_labels)

    return(data_sets)
}


fit_xgboost_on_bootstrap <- function(split) {
    split_training <- analysis(split)

    training_data <- prep_data_for_xgb(split_training)
    dtrain <- xgb.DMatrix(data = training_data[["data"]], label = training_data[["labels"]])

    split_testing <- assessment(split)


    testing_data <- prep_data_for_xgb(split_testing)
    dtest <- xgb.DMatrix(data = testing_data[["data"]], label = testing_data[["labels"]])

    watchlist <- list(train = dtrain, test = dtest)

    bst <- xgb.train(
        data = dtrain,
        max.depth = 2,
        eta = 1,
        nthread = 4,
        nrounds = 100,
        watchlist = watchlist,
        objective = "binary:logistic"
    )
    return(bst)
}

# We don't normalize the variables in this function because xgboost sometimes won't
# use certain variables, which we'll set to 0 after joining with the LASSO importances before
# normalizing
get_xgboost_importances <- function(boot_splits) {
    bootstrapped_samples %>%
        select(xgb.model) %>%
        transmute(xgb.var_imps = map(xgb.model, ~ xgb.importance(model = .x))) %>%
        pluck("xgb.var_imps") %>%
        reduce(left_join, by = "Feature") %>%
        select(-contains(c("Frequency", "Cover"))) %>%
        mutate(xgb_importance = rowSums(across(-Feature), na.rm = TRUE), .keep = "unused") %>%
        as.data.frame()
}


############ Metric calculations for Naive model
# Based on: http://rstudio-pubs-static.s3.amazonaws.com/370944_96c386c03ac54ef3bec4535d49e92890.html
calc_accuracy <- function(confusion_table) {
    tp <- confusion_table[2, 2]
    tn <- confusion_table[1, 1]
    fn <- confusion_table[1, 2]
    fp <- confusion_table[2, 1]
    accuracy <- round((tp + tn) / sum(tp, fp, tn, fn), 2)
    return(accuracy)
}

# Sensitivity and specificity are reversed here: a HAB observation is the
# negative event
calc_specificity <- function(confusion_table) {
    tp <- confusion_table[2, 2]
    fn <- confusion_table[1, 2]
    sensitivity <- round(tp / (tp + fn), 2)
    return(sensitivity)
}

calc_sensitivity <- function(confusion_table) {
    tn <- confusion_table[1, 1]
    fp <- confusion_table[2, 1]
    specificity <- round(tn / (tn + fp), 2)
    return(specificity)
}

add_naive_results <- function(df, confusion_table, naive_auc) {
    df %>%
        add_row(
            rank = 5,
            wflow_id = "naive",
            .metric = "accuracy",
            mean = calc_accuracy(confusion_table),
            std_err = 0,
            model = "naive",
            sampling_strategy = "naive"
        ) %>%
        add_row(
            rank = 5,
            wflow_id = "naive",
            .metric = "roc_auc",
            mean = naive_auc,
            std_err = 0,
            model = "naive",
            sampling_strategy = "naive"
        ) %>%
        add_row(
            rank = 5,
            wflow_id = "naive",
            .metric = "sens",
            mean = calc_sensitivity(confusion_table),
            std_err = 0,
            model = "naive",
            sampling_strategy = "naive"
        ) %>%
        add_row(
            rank = 5,
            wflow_id = "naive",
            .metric = "spec",
            mean = calc_specificity(confusion_table),
            std_err = 0,
            model = "naive",
            sampling_strategy = "naive"
        )
}

## Helper to quickly investigate predictions
get_prediction_metrics <- function(prediction_df, prediction_target, class_estimate, class_pred) {
    prediction_target <- enquo(prediction_target)
    class_estimate <- enquo(class_estimate)
    class_pred <- enquo(class_pred)

    df <- rbind(
        roc_auc = yardstick::roc_auc(prediction_df, !!prediction_target, !!class_estimate),
        acc = accuracy(prediction_df, !!prediction_target, !!class_pred),
        sens = sens(prediction_df, !!prediction_target, !!class_pred),
        spec = spec(prediction_df, !!prediction_target, !!class_pred)
    )

    return(df)
}

## Get the mode of a row
getmode <- function(v) {
    uniqv <- unique(v)
    uniqv[which.max(tabulate(match(v, uniqv)))]
}
