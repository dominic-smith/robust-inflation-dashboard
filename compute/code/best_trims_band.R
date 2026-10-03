# Live "range across best trims" — the paper's Figure 1 / Prediction_Levels band,
# recomputed each month on the current BEA vintage.
#
# Which trims are statistically equivalent to the best (DM p >= 0.05) is a paper
# result, read from data/1_raw/equiv_sets.csv (written by analytical/extract_heatmap.R).
# Each month every trim in those sets is applied to the current data, and the band
# is built exactly as in Trimmed_Mean_HeatMap.R: per month take the min / max / mean
# of the trims' annualized monthly rates, then chain 12 months (current month included).
# Sourced by run_compute.R after 22m (needs group-4 relatives and the trim engine).

eq <- readr::read_csv("../data/1_raw/equiv_sets.csv", show_col_types = FALSE)
trims <- unique(eq[c("lb", "ub")])
message("best-trims band: ", nrow(trims), " distinct trims across ", nrow(unique(eq[c("target", "sample")])), " sets")

prep <- trim_prep(group = "4", freq = "M", lag = 1, weights = "DAL")
key <- paste(trims$lb, trims$ub, sep = "_")
res1 <- trim_combo(prep, trims$lb[1], trims$ub[1])$result
dates <- res1$date
A <- matrix(NA_real_, nrow = length(dates), ncol = nrow(trims), dimnames = list(NULL, key))
for (j in seq_len(nrow(trims))) {
  r <- if (j == 1) res1 else trim_combo(prep, trims$lb[j], trims$ub[j])$result
  stopifnot(identical(r$date, dates))
  A[, j] <- ((1 + r$trimmed_mean_1 / 100)^12 - 1) * 100   # annualized monthly (paper's M)
}

chain12 <- function(x) {                                 # annualized monthly % -> 12-month %
  g <- (1 + x / 100)^(1 / 12)
  out <- rep(NA_real_, length(g))
  for (i in 12:length(g)) out[i] <- (prod(g[(i - 11):i]) - 1) * 100
  out
}
rowfun <- function(M, f) { v <- suppressWarnings(apply(M, 1, f)); v[!is.finite(v)] <- NA; v }

sets <- unique(eq[c("target", "sample")])
band <- dplyr::bind_rows(lapply(seq_len(nrow(sets)), function(i) {
  e <- eq[eq$target == sets$target[i] & eq$sample == sets$sample[i], ]
  M <- A[, paste(e$lb, e$ub, sep = "_"), drop = FALSE]
  data.frame(date = dates, target = sets$target[i], sample = sets$sample[i],
             lo = chain12(rowfun(M, min)), hi = chain12(rowfun(M, max)),
             mean = chain12(rowMeans(M)), n_trims = ncol(M))
}))
band <- band[!is.na(band$lo), ]
write_done(band, "d_best_trims_band")
message("best-trims band: wrote ", nrow(band), " rows through ", tm_label(max(band$date)))
