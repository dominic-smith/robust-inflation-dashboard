# Robustness heatmap cells for one category set (4 = all categories, 5 = excluding
# housing). Definitions in heat-common.R.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
source(file.path(here, "..", "heat-common.R"))
g <- as.integer(param("g")); stopifnot(g %in% c(4L, 5L))
emit(heat_table[heat_table$group == g, -1])
