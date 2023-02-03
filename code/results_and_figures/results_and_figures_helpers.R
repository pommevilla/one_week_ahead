# ---------------------------
# Various functions to help with creating results and figures
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

###### Theme for plots

theme_nice <- theme_light() +
    theme(
        panel.grid = element_blank(),
        panel.grid.major.x = element_line(
            color = "gray75",
            linetype = "dashed",
            linewidth = 0.5
        ),
        plot.title = element_text(size = 10),
        plot.subtitle = element_text(size = 5),
        axis.ticks.length = unit(0.25, "cm"),
        axis.ticks.x = element_blank(),
        axis.text.x = element_text(face = "bold"),
        panel.border = element_blank(),
        axis.ticks = element_blank(),
    )
