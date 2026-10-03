# Pack the human-readable artifacts (artifacts/*.csv, committed) into the single
# compressed file the app reads (app/data/dashboard.rds). Keeps the in-browser app
# fast: one small binary file, no CSV parser package to download, nothing to parse.
# Run from compute/code/ after export_artifacts.R (and after extract_heatmap.R).

suppressPackageStartupMessages({library(readr); library(dplyr)})
ART <- "../../artifacts"
APP <- "../../app/data"
dir.create(APP, showWarnings = FALSE, recursive = TRUE)

rd <- function(f, ...) read_csv(file.path(ART, f), show_col_types = FALSE, ...)
sig <- function(df) mutate(df, across(where(function(x) is.double(x) && !inherits(x, "Date")), ~ signif(.x, 5)))   # display needs < 5 digits

vin <- jsonlite::fromJSON(file.path(ART, "vintage.json"))
d <- list(
  vintage        = vin,
  series_h       = rd("series_h.csv") |> sig(),
  distribution_h = rd("distribution_h.csv") |> mutate(category = trimws(category)) |> sig(),
  heat           = rd("heatmap_rmse.csv", col_types = "ccciidd") |> sig(),
  heat_refs      = rd("heatmap_refs.csv", col_types = "ccccdii") |> sig(),
  heat_dm        = rd("heatmap_dm.csv", col_types = "cciid") |> sig(),
  band           = rd("best_trims_band.csv") |> sig(),
  pct_h          = rd("percentiles_h.csv") |> sig()
)
d <- lapply(d, function(x) if (is.data.frame(x)) as.data.frame(x) else x)   # plain data.frames: no tibble needed to read

out <- file.path(APP, "dashboard.rds")
saveRDS(d, out, compress = "xz")
# the app folder carries only the packed file (shinylive bundles everything in app/)
stale <- setdiff(list.files(APP), "dashboard.rds")
if (length(stale)) file.remove(file.path(APP, stale))
message(sprintf("Packed %d tables into %s (%.0f KB)", length(d) - 1, out, file.size(out) / 1024))
