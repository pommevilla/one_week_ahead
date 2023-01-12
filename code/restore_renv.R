#!/usr/bin/env Rscript
# ---------------------------
# Restores the r environment used in the project.
# This is necessary because not all packages (such as janitor and tidyverse)
# are available through Anaconda.
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

renv::install()
