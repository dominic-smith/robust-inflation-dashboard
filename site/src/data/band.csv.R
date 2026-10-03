# Live range across the paper's statistically-equivalent best trims (Figure 1):
# one row per month x trend measure x selection sample.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
b <- artifact("best_trims_band.csv")
for (v in c("lo", "hi", "mean")) b[[v]] <- round(b[[v]], 3)
emit(b[c("date", "target", "sample", "lo", "hi", "mean", "n_trims")])
