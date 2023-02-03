#!/usr/bin/env Rscript
# ---------------------------
# Generates feature selection plots.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------
library(tidyverse)
library(patchwork)

source("code/results_and_figures/results_and_figures_helpers.R")

feature_importances <- read.csv("data/model_training/feature_importances.csv")

lasso_importance_plot <- feature_importances %>%
    mutate(nice_name = fct_reorder(nice_name, -lasso_importance)) %>% 
    ggplot(aes(lasso_importance, nice_name)) +
    geom_col() +
    theme_nice +
    labs(
        x = "LASSO variable importance",
        y = "Factor"
    )

ggsave("figures/feature_importance/lasso_importances.png")

xgboost_importance_plot <- feature_importances %>%
    mutate(nice_name = fct_reorder(nice_name, -xgb_importance)) %>% 
    ggplot(aes(xgb_importance, nice_name)) +
    geom_col() +
    theme_nice +
    labs(
        x = "XGBoost variable importance",
        y = "Factor"
    )

ggsave("figures/feature_importance/xgb_importances.png")


ani_plot <- feature_importances %>%
    mutate(nice_name = fct_reorder(nice_name, a_n_importance)) %>% 
    ggplot(aes(a_n_importance, nice_name)) +
    geom_col() +
    theme_nice +
    labs(
        x = "Average normalized feature importance",
        y = "Factor"
    )

ggsave("figures/feature_importance/ani_importances.png")

top_row <- lasso_importance_plot + (
    xgboost_importance_plot +
    labs(y = "")
)

top_row + 
    theme(aspect.ratio = 1)

bottom_row  <- (plot_spacer() + ani_plot + plot_spacer()) +
    plot_layout(widths = c(1, 2, 1))

importances_figure_plot <- top_row / ani_plot +
    plot_annotation(tag_levels = "A", tag_suffix = ")") +
    plot_layout(
        heights = c(1, 1.5)
    )

ggsave("figures/feature_importance/all_importances.png")
