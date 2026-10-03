# Headline, core, median and trimmed-mean inflation at 1m / 3m (annualized) and 12m.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
s <- artifact("series_h.csv")
s$value <- round(s$value, 6)
emit(s[c("date", "measure", "horizon", "value")])
