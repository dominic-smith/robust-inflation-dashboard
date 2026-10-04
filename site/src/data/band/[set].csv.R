# Range across the paper's statistically-equivalent best trims (paper Figure 1) for one
# set, named <trend measure>-<selection sample>, e.g. c_0_37-long: 12-month min, max
# and mean across the set's trims, recomputed on the current BEA vintage.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
set <- param("set")
target <- sub("-[^-]+$", "", set); sample <- sub("^.*-", "", set)
b <- artifact("best_trims_band.csv"); b <- b[b$target == target & b$sample == sample, ]
stopifnot(nrow(b) > 0)
emit(data.frame(date = b$date, lo = r6(b$lo), hi = r6(b$hi), mean = r6(b$mean)))
