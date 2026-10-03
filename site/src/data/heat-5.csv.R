# Robustness heatmap cells for category set 5 (see heat-common.R for the definitions).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R")); source(file.path(here, "heat-common.R"))
emit(heat_table[heat_table$group == 5, -1])
