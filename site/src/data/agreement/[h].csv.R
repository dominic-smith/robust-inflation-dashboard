# Spread across the robust measures (core, median, trimmed mean) at one horizon (the
# paper's App. Fig. B.1), plus headline at the same horizon.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "..", "artifacts.R"))
h <- param("h"); stopifnot(h %in% HORIZONS)
s <- artifact("series_h.csv"); s <- s[s$horizon == h, ]
r <- s[s$measure %in% ROBUST, ]
lo <- tapply(r$value, r$date, min); hi <- tapply(r$value, r$date, max)
hl <- s[s$measure == "Headline PCE", ]
d <- data.frame(date = names(lo), lo = r6(lo), hi = r6(hi), spread = r6(hi - lo),
                headline = r6(hl$value[match(names(lo), hl$date)]))
emit(d[order(d$date), ])
