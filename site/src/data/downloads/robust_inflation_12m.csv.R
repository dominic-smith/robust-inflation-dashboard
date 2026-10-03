# Download: monthly series for all four measures at the 12m horizon (full precision).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
s <- artifact("series_h.csv"); s <- s[s$horizon == "12m", ]
w <- reshape(s[c("date", "measure", "value")], idvar = "date", timevar = "measure", direction = "wide")
names(w) <- sub("^value\\.", "", names(w)); names(w)[1] <- "month"
emit(w[order(w$month), c("month", "Headline PCE", "Core PCE", "Cleveland median", "Dallas trimmed mean")])
