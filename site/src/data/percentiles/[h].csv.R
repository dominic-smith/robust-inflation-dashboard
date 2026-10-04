# Paper Figure 2: 10/24/50/69/90th spending-weighted percentiles of category price
# changes each month, at one horizon.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
h <- param("h"); stopifnot(h %in% HORIZONS)
p <- artifact("percentiles_h.csv"); p <- p[p$horizon == h, ]
for (v in c("p10", "p24", "p50", "p69", "p90")) p[[v]] <- r6(p[[v]])
emit(p[c("date", "p10", "p24", "p50", "p69", "p90")])
