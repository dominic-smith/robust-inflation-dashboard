# One-time check after re-running extract_heatmap.R: the live band must reproduce
# the paper's published band (Prediction_Ranges.xlsx) on years BEA has not revised.
# Run from compute/analytical/ after run_compute.R.
suppressPackageStartupMessages({library(dplyr); library(readxl)})
paper <- read_excel("/Users/smith_d/Dropbox (Work)/Research/ExtendingTheRange_IJCB/output/HeatMaps/Prediction/Prediction_Ranges.xlsx")
mine <- readRDS("../data/3_done/d_best_trims_band.rds")
yr <- function(dm) 1960 + dm %/% 12
cat(sprintf("%-8s %-4s  %-9s  %8s  %8s  %8s\n", "target", "smp", "period", "n", "mean|d|", "max|d|"))
for (o in c("c_0_37", "f_12_24", "f_0_24", "b_2_39")) for (s in c("long", "80s", "00s")) {
  p <- paper |> transmute(date, p_lo = .data[[paste0("top_5p_min_", o, "_", s)]],
                          p_hi = .data[[paste0("top_5p_max_", o, "_", s)]])
  m <- mine |> filter(target == o, sample == s)
  j <- inner_join(p, m, by = "date") |> filter(!is.na(p_lo)) |>
    mutate(d = pmax(abs(lo - p_lo), abs(hi - p_hi)))
  for (per in list(c(1970, 2018), c(2019, 2024))) {
    k <- j[yr(j$date) >= per[1] & yr(j$date) <= per[2], ]
    if (nrow(k)) cat(sprintf("%-8s %-4s  %d-%d  %8d  %8.4f  %8.4f\n", o, s, per[1], per[2],
                             nrow(k), mean(k$d), max(k$d)))
  }
}
