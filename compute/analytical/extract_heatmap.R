# ONE-TIME / ANNUAL extract of the paper's analytical layer (the trim-grid RMSE
# surfaces) into the dashboard's app/data/. This is NOT part of the monthly
# refresh: the optimal-trim / prediction results are a paper finding, refreshed
# only when the authors rerun the prediction analysis. It reads the paper repo's
# output/ once; the committed CSVs are what the app actually uses.
#
#   Rscript extract_heatmap.R ["/path/to/ExtendingTheRange_IJCB/output"]
#
# Produces:
#   app/data/heatmap_rmse.csv  group, sample, target, lb, beta, rmse
#   app/data/heatmap_refs.csv  group, sample, target, measure, rmse (+ best trim)

suppressPackageStartupMessages({library(readxl); library(readr); library(dplyr)})

args <- commandArgs(trailingOnly = TRUE)
PAPER_OUT <- if (length(args) >= 1) args[[1]] else
  "/Users/smith_d/Dropbox (Work)/Research/ExtendingTheRange_IJCB/output"
# Run from compute/analytical/; app/data is two levels up.
APP_DATA <- normalizePath("../../app/data", mustWork = FALSE)
if (!dir.exists(APP_DATA))
  APP_DATA <- normalizePath("~/Developer/robust-inflation-dashboard/app/data")

groups  <- c("4", "5")
samples <- c("long", "80s", "00s")
targets <- c("c_0_37", "f_0_24", "f_12_24", "b_2_39")
# DALagg reference rows, in file order (per the heatmap script): agg, core, nyf, median, trim
ref_names <- c("Headline PCE", "Core PCE", "NY Fed UIG", "Median PCE", "Trimmed mean")

grid_rows <- list(); ref_rows <- list()
for (g in groups) for (s in samples) {
  Data <- read_excel(file.path(PAPER_OUT, g, sprintf("d28m_%s_1_DAL_1.xlsx", s)))
  Ref  <- read_excel(file.path(PAPER_OUT, g, sprintf("d28m_%s_1_DALagg_1.xlsx", s)))
  Data$beta <- 100 - Data$ub                       # upper trim beta (matches paper)
  for (o in targets) {
    rmse <- sqrt(Data[[paste0("mean_p_", o)]])
    best <- which.min(rmse)
    grid_rows[[length(grid_rows) + 1]] <- data.frame(
      group = g, sample = s, target = o,
      lb = Data$lb, beta = Data$beta, rmse = rmse)
    rref <- sqrt(Ref[[paste0("mean_p_", o)]])
    ref_rows[[length(ref_rows) + 1]] <- data.frame(
      group = g, sample = s, target = o,
      measure = c(ref_names, "Best trim"),
      rmse = c(rref, rmse[best]),
      best_lb = Data$lb[best], best_beta = Data$beta[best])
  }
}

# DM-equivalence p-values (group 4) from the paper's heatmap step. Vector order is
# lb 0:50 outer, ub 100:50 inner — the paper's trim-column order (verified against
# d31m_prediction_series). The best trim itself has p = NA.
grid_lb <- rep(0:50, each = 51); grid_ub <- rep(100:50, times = 51)
dm_rows <- list(); eq_rows <- list()
for (o in targets) for (s in samples) {
  p <- readRDS(file.path(PAPER_OUT, sprintf("p_DM_vec_%s_%s.rds", o, s)))
  stopifnot(length(p) == 2601)
  dm_rows[[length(dm_rows) + 1]] <- data.frame(target = o, sample = s, lb = grid_lb,
                                               beta = 100 - grid_ub, p = round(p, 4))
  # The paper's equivalence set (Figure 1 band): p >= 0.05, which excludes the
  # best trim (p = NA) exactly as in Trimmed_Mean_HeatMap.R.
  k <- which(!is.na(p) & p >= 0.05)
  eq_rows[[length(eq_rows) + 1]] <- data.frame(target = o, sample = s,
                                               lb = grid_lb[k], ub = grid_ub[k])
}
write_csv(bind_rows(dm_rows), file.path(APP_DATA, "heatmap_dm.csv"))
# Static input for the live band (compute/data/1_raw, committed; read by best_trims_band.R)
write_csv(bind_rows(eq_rows), "../data/1_raw/equiv_sets.csv")

grid <- bind_rows(grid_rows)
refs <- bind_rows(ref_rows)
write_csv(grid, file.path(APP_DATA, "heatmap_rmse.csv"))
write_csv(refs, file.path(APP_DATA, "heatmap_refs.csv"))

# stamp the analytical-layer vintage separately from the monthly series
writeLines(sprintf('{\n  "heatmap_source": "Ocampo-Schoenle-Smith prediction analysis (paper vintage)",\n  "extracted_at": "%s",\n  "n_cells": %d\n}\n',
  format(Sys.time(), "%Y-%m-%d"), nrow(grid)),
  file.path(APP_DATA, "heatmap_vintage.json"))

cat("Wrote heatmap_rmse.csv (", nrow(grid), "rows) and heatmap_refs.csv (", nrow(refs), "rows) to\n  ", APP_DATA, "\n")
