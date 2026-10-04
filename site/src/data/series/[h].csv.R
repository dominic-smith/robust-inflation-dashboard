# The four measures at one horizon (1m and 3m are annualized): date, measure, value.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
h <- param("h"); stopifnot(h %in% HORIZONS)
s <- artifact("series_h.csv"); s <- s[s$horizon == h, ]
emit(data.frame(date = s$date, measure = s$measure, value = r6(s$value)))
