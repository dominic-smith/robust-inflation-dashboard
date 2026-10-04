# Average spread across the robust measures, per horizon: latest month, all months,
# and by inflation regime (headline < 2.5% vs >= 5% at the same horizon).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
s <- artifact("series_h.csv")
out <- lapply(HORIZONS, function(h) {
  x <- s[s$horizon == h & s$measure %in% ROBUST, ]
  sp <- tapply(x$value, x$date, function(v) max(v) - min(v))
  hl <- s[s$measure == "Headline PCE" & s$horizon == h, ]
  hv <- hl$value[match(names(sp), hl$date)]
  last <- max(names(sp))
  list(horizon = h, latest_date = last, latest = r6(unname(sp[last])), average = r6(mean(sp)),
       low = r6(mean(sp[!is.na(hv) & hv < 2.5])), high = r6(mean(sp[!is.na(hv) & hv >= 5])))
})
emit_json(out)
