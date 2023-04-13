#!/usr/bin/env Rscript
# ---------------------------
# This creates the historic HAB occurence plot for the DNR data.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

######## Setup
library(tidyverse)
library(readxl)
library(janitor)
library(lubridate)
library(patchwork)


######## Reading in data

# Reading in current data.
current_data <- read.csv("data/dnr_data/dnr_combined.csv") %>%
    mutate(
        collected_date = as.Date(collected_date),
        year = year(collected_date),
    ) %>%
    select(
        station_name = environmental_location,
        date = collected_date,
        microcystin,
        year,
    )

# Reading in historic data. There's a lot of renaming that needs to happen
# to be consistent with the beach names in the current study.
historic_data <- readxl::read_xlsx(
    "data/dnr_data/Microcystin2005-2016forEPA_all.xlsx",
    sheet = "cleaned"
) %>%
    mutate(
        Date = as.Date(Date),
        Year = year(Date)
    ) %>%
    select(
        station_name = `Station Name`,
        date = Date,
        microcystin = Result,
        environmental_location = LAKE_NAME,
        year = Year
    ) %>%
    mutate(
        microcystin = replace_na(as.numeric(microcystin), 0),
        station_name = str_replace(station_name, " \\s*\\([^\\)]+\\)", "")
    ) %>%
    # Removing this year because most locations don't have data for this year
    filter(year != 2005) %>%
    # Renaming some stations to match the current data
    mutate(
        station_name = case_when(
            str_detect(station_name, "Black Hawk Campground Beach") ~ "Black Hawk Beach",
            str_detect(station_name, "Brushy Creek") ~ "Brushy Creek Beach",
            str_detect(station_name, "Honey Creek Resort") ~ "Honey Creek Resort Beach",
            str_detect(station_name, "Clear Lake") ~ "Clear Lake Beach",
            str_detect(station_name, "McIntosh Beach") ~ "McIntosh Woods Beach",
            str_detect(station_name, "Pleasant Creek Beach") ~ "Pleasant Creek",
            str_detect(station_name, "Pine Lake South Beach") ~ "Lower Pine Lake Beach",
            str_detect(station_name, "Blue Lake") ~ "Lewis and Clark (Blue Lake) Beach",
            TRUE ~ station_name
        )
    )

# Prepare and combine the data. The sample is considered a harmful algal bloom (hazardous)
# if the microcystin concentration is greater than 8 ug/L. We count the number of such occurrences
# at each location for each year, then fill in the missing values with NA.
all_data <- bind_rows(
    historic_data,
    current_data
) %>%
    filter(station_name %in% current_data$station_name) %>%
    mutate(hazardous = if_else(microcystin > 8, "Hazardous", "Safe")) %>%
    count(station_name, year, hazardous) %>%
    pivot_wider(
        names_from = hazardous,
        values_from = n,
        values_fill = 0
    ) %>%
    select(-c(`NA`, Safe)) %>%
    complete(station_name, year, fill = list(Hazardous = NA)) %>%
    mutate(
        year = as.character(year),
        when = if_else(year > 2017, "Current Study", "Historic Data"),
        when = factor(when, levels = c("Historic Data", "Current Study"))
    ) %>%
    rename(n = Hazardous)



######## Plotting
this_palette <- c(viridis::mako(n = max(all_data$n, na.rm = TRUE), direction = -1))

plot_hab_counts <- function(hab_count_df) {
    hab_count_df %>%
        ggplot(aes(year, station_name)) +
        geom_tile(color = "white", aes(fill = n), size = 0.75) +
        # This is to get the NA values to show up in the legend
        geom_point(aes(size = "NA"), shape = NA, color = "gray") +
        scale_fill_gradientn(
            colors = this_palette,
            na.value = "gray",
            guide = guide_colorbar(
                frame.colour = "black",
                ticks = TRUE,
                nbin = 10,
                barwidth = 2
            )
        ) +
        theme(
            text = element_text(family = "Times New Roman"),
            axis.ticks = element_blank(),
            panel.background = element_rect(color = "NA", fill = "NA", linewidth = 1),
            strip.background = element_blank(),
            strip.text = element_text(size = 18),
            axis.text.x = element_text(size = 10),
            axis.text.y = element_text(size = 14),
            axis.line.x.bottom = element_line(color = "black"),
        ) +
        scale_color_manual(values = "black", labels = "Missing value") +
        labs(
            x = "",
            y = "",
            fill = "# Hazardous Cases",
            size = "No data"
        ) +
        scale_y_discrete(limits = rev) +
        facet_grid(~when) +
        coord_equal()
}

# I had to break up the plot in two steps in order to get square tiles to work with
# free scales in the facet_grid.
current_hab_counts <- all_data %>%
    filter(when == "Current Study") %>%
    plot_hab_counts() +
    theme(
        axis.text.y = element_blank()
    )

historic_hab_counts <- all_data %>%
    filter(when == "Historic Data") %>%
    plot_hab_counts() +
    theme(
        legend.position = "none"
    )


# Combining the two plots
historic_hab_counts + current_hab_counts +
    theme(
        strip.clip = "off",
        legend.key.size = unit(1, "cm"),
    ) +
    guides(
        shape = guide_legend(order = 1)
    )


# The tiff version is for the paper, the png version is for the website
ggsave(
    "figures/historical_hab_occurrences.tiff",
    device = "tiff",
    width = 16.5,
    height = 16.5,
)

ggsave(
    "figures/historical_hab_occurrences.png",
    width = 16.5,
    height = 16.5,
)
