#!/usr/bin/env Rscript
# ---------------------------
# Creates various histograms for the DNR dataset
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

# Setup
library(tidyverse)
library(patchwork)
library(ggbreak)

# Load in unmodified DNR data, filtering out rows without microcystin values,
# adding a year column for a later plot, adding a nice name for plotting
dnr_all <- read.csv("data/dnr_data/dnr_combined.csv") %>%
    filter(!is.na(microcystin)) %>%
    mutate(year = lubridate::year(collected_date)) %>%
    mutate(nice_category_name = if_else(category_d == 1, "Non-hazardous", "Hazardous"))

# Get class counts for figure caption
class_counts <- dnr_all %>%
    count(nice_category_name)

class_counts_annotation <- str_glue(
    "Hazardous samples: {class_counts[1, 2]}\nNon-hazardous samples: {class_counts[2, 2]}"
)

# This data frame will be used to plot the 8 ug/L EPA threshold on the histogram
# This is used because we want the line to start at 0, regardless of the expansion of the
# plot axes.
epa_thresh <- data.frame(
    x1 = 8, x2 = 8,
    y1 = 0, y2 = Inf
)

# This controls the bin width for the histogram, which is used to dynamically
# calculate x axis breaks. Another bin width considered was 2, but we went with 4
# because a bin width of 2 resulted in a plot that was too busy.
this_bin_width <- 4


# Making the base plot. Unfortunately, ggbreak does not play nicely with the nice_theme
# I used for the feature importance plots, so we have to redefine all the theme arguments
# here.
this_text_size <- 14

microcystin_histogram <- dnr_all %>%
    ggplot(aes(microcystin)) +
    geom_histogram(
        color = "black",
        fill = "gray",
        breaks = seq(0, 90, by = this_bin_width),
        linewidth = 0.25
    ) +
    labs(
        x = "Microcystin (ug/L)",
        y = "Count"
    ) +
    scale_x_continuous(
        breaks = seq(0, 90, by = this_bin_width * 2),
        expand = expansion(add = 1)
    ) +
    scale_y_continuous(
        breaks = seq(0, 1600, by = 50),
    ) +
    theme_light() +
    theme(
        text = element_text(family = "Times New Roman", size = this_text_size),
        panel.grid.major.x = element_blank(),
        panel.border = element_blank(),
        axis.ticks.length = unit(0.25, "cm"),
        axis.ticks = element_line(color = "black", linewidth = 0.25),
        panel.grid = element_blank(),
        axis.text.y.right = element_blank(),
        axis.ticks.y.right = element_blank(),
        axis.text.y.left = element_text(margin = margin(0)),
    ) +
    annotate(
        "text",
        label = class_counts_annotation,
        x = 88,
        y = 1430,
        family = "Times New Roman",
        size = this_text_size / .pt,
        hjust = 1
    ) +
    scale_y_break(
        c(105, 1400),
        space = unit(0.5, "cm"),
        # expand = expansion(mult = c(0, 0.1), add = 0)
        expand = FALSE
    )

ggsave(
    "figures/microcystin_histogram.tiff",
    device = "tiff"
)

microcystin_histogram_threshed <- microcystin_histogram +
    geom_segment(
        data = epa_thresh,
        aes(x = x1, y = y1, xend = x2, yend = y2),
        color = "red",
        linetype = "solid"
    )

ggsave(
    "figures/microcystin_histogram_threshed.tiff",
    device = "tiff"
)
