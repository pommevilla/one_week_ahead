#!/usr/bin/env Rscript
# ---------------------------
# Outputs figures related to model metrics
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

library(tidyverse)
library(here)

theme_set(theme_minimal())

model_metrics <- read.csv(here("data/model_training/", "training_results.csv")) 

model_metrics %>% 
  group_by(wflow_id, .metric, model, sampling_strategy) %>% 
  summarise(across(mean:std_err, ~ mean(.))) %>% 
  ungroup() %>% 
  mutate(
    across(wflow_id:sampling_strategy, ~ str_to_title(str_replace_all(., "_", " ")))
  ) %>% 
  select(
    model, sampling_strategy, everything()
  )
  ggplot(aes(wflow_id, mean, color = model, shape = sampling_strategy)) +
  facet_grid(~ .metric) +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = mean - std_err, ymax = mean + std_err),
    width = 0.1
  ) +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5),
    panel.border = element_rect(color = "black", fill = NA),
    panel.grid = element_blank(),
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed")
  ) +
  labs(
    x = "Workflow ID",
    y = "Mean",
    shape = "Sampling Strategy",
    color = "Model"
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2)
  )
  


