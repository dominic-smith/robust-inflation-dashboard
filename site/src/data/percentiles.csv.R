# Paper Figure 2: 10/24/50/69/90th weighted percentiles of category price changes.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
p <- artifact("percentiles_h.csv")
for (v in c("p10", "p24", "p50", "p69", "p90")) p[[v]] <- round(p[[v]], 6)
emit(p[c("date", "horizon", "p10", "p24", "p50", "p69", "p90")])
