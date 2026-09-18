# Dashboard compute driver — reproduces the four headline measures (+ the range
# inputs) from the current BEA vintage, reusing the paper's exact code.
#
# Mirrors batches 1-3 of the paper's readme.R, pruned to what the dashboard needs:
#   01m load  -> 02m grouping -> 10m relatives -> two trims -> 21m median -> 22m combine
# The 51x51 optimal-trim grid, prediction, and heatmaps (paper's analytical layer)
# are deliberately NOT run here.
#
# Assumes data/1_raw/Section2All_xls.xlsx is present (run download_bea.R first).
# Working directory is set to this script's folder so ../data paths resolve.

args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", grep("^--file=", args, value = TRUE))
if (length(script) > 0) setwd(dirname(normalizePath(script)))

source("ado/setup_compute.R")

run <- function(path) {
  message("==== ", path, " ====")
  t0 <- Sys.time()
  sys.source(path, envir = globalenv())
  message("     done (", round(difftime(Sys.time(), t0, units = "secs"), 1), "s)")
}

# Batch 1: cleaning + relatives
run("1_cleaning/01m-load_data.R")
run("1_cleaning/02m-clean_pce.R")
run("2_analysis/10m-create_relatives.R")

# Batch 2 (pruned): only the two trims the dashboard uses, applied directly.
#   median_pce  = 50/50 Passche-weighted trim on the Cleveland category set
#   trimmed_mean = Dallas 24/69 trim (the official-comparable measure)
message("==== trims (DAL 24/69, CLE 50/50) ====")
trimmed_mean_single("DAL", "M", 1, "DAL", 24, 69)
trimmed_mean_single("CLE", "M", 1, "pas", 50, 50)

# Batch 2 cont.: chained monthly median (fills any dates the 50/50 trim misses)
run("2_analysis/21m-median_pce.R")

# Batch 3: combine into the aggregate time series (d22m_agg_time_series[_1])
run("2_analysis/22m-combine_measures.R")

message("\nCompute done. Series written to data/3_done/d22m_agg_time_series.rds")
message("Next: Rscript export_artifacts.R")
