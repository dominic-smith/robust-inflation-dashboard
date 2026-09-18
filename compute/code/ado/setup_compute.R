# Dashboard compute setup — a trimmed copy of the pipeline's ado/setup.R.
# Differences from the paper's setup: it does NOT fetch Chan/Stock-Watson trend
# estimates (the dashboard computes only the four headline measures + range, none
# of which need the trend targets). Everything else mirrors the paper exactly.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(purrr)
  library(readxl)
  library(haven)
  library(ggplot2)
})

GLOBALS <- new.env(parent = emptyenv())
GLOBALS$figures <- "./figures"
# Only the groups the dashboard's measures need are computed by 10m's group loop;
# CLE and DAL relatives are created by explicit calls in main_10m regardless.
GLOBALS$groups <- character(0)
GLOBALS$freqs  <- "M"

GLOBALS$agg_color    <- "#1F5889"
GLOBALS$core_color   <- "#9B343A"
GLOBALS$median_color <- "#5E8232"
GLOBALS$trim_color   <- "#E37E00"

source("ado/io.R")
source("ado/stata_time.R")
source("ado/stata_compat.R")
source("ado/lag_list.R")
source("ado/tex_numbers.R")
source("ado/theme_inflation.R")
source("ado/trim_core.R")

ensure_dirs()
