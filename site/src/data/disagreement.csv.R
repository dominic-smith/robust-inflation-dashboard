# Measure disagreement: per month and horizon, the min / max / spread across core PCE,
# the median and the trimmed mean (same definition as the paper's App. Fig. B.1),
# plus headline at the same horizon (used to split months by inflation regime).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
s <- artifact("series_h.csv")
r <- s[s$measure %in% c("Core PCE", "Cleveland median", "Dallas trimmed mean"), ]
lo <- aggregate(value ~ date + horizon, r, min); names(lo)[3] <- "lo"
hi <- aggregate(value ~ date + horizon, r, max); names(hi)[3] <- "hi"
d <- merge(lo, hi, by = c("date", "horizon"))
hl <- s[s$measure == "Headline PCE", c("date", "horizon", "value")]; names(hl)[3] <- "headline"
d <- merge(d, hl, by = c("date", "horizon"), all.x = TRUE)
d$diff <- d$hi - d$lo
for (v in c("lo", "hi", "diff", "headline")) d[[v]] <- round(d[[v]], 6)
emit(d[order(d$horizon, d$date), c("date", "horizon", "lo", "hi", "diff", "headline")])
