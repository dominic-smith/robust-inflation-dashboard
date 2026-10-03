# Summary spreads per horizon: latest month, all months, and by inflation regime
# (headline < 2.5% vs >= 5%, at the same horizon).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
s <- artifact("series_h.csv")
r <- s[s$measure %in% c("Core PCE", "Cleveland median", "Dallas trimmed mean"), ]
out <- lapply(c("1m", "3m", "12m"), function(h) {
  x <- r[r$horizon == h, ]
  sp <- tapply(x$value, x$date, function(v) max(v) - min(v))
  hl <- s[s$measure == "Headline PCE" & s$horizon == h, ]
  hv <- hl$value[match(names(sp), hl$date)]
  list(horizon = h, latest_date = max(names(sp)), latest = unname(sp[max(names(sp))]),
       average = mean(sp), low = mean(sp[!is.na(hv) & hv < 2.5]), high = mean(sp[!is.na(hv) & hv >= 5]))
})
cat(jsonlite::toJSON(out, auto_unbox = TRUE, digits = 6))
