# Number of trims in each equivalence set (fixed by the paper's evaluation).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
b <- artifact("best_trims_band.csv")
m <- unique(b[c("target", "sample", "n_trims")])
emit_json(m)
