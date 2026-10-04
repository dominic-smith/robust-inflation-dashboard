# Download: the four measures at one horizon, one column each, full precision.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
h <- param("h"); stopifnot(h %in% HORIZONS)
s <- artifact("series_h.csv"); s <- s[s$horizon == h, ]
w <- reshape(s[c("date", "measure", "value")], idvar = "date", timevar = "measure", direction = "wide")
names(w) <- sub("^value[.]", "", names(w)); names(w)[1] <- "month"
emit(w[order(w$month), c("month", "Headline PCE", "Core PCE", "Median PCE", "Trimmed-mean PCE")])
