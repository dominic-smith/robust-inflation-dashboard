# Latest-month cross-section of category price changes, per horizon:
#  - 1pp histogram bins (spending-weighted), each flagged kept vs trimmed by the trimmed
#    mean's cut points (lightest 24% / heaviest 31% of spending)
#  - the categories it trims, ranked by approximate contribution to headline
#    (spending weight x price change, percentage points)
#  - the four measures at that month, to mark on the histogram
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
d0 <- artifact("distribution_h.csv"); s <- artifact("series_h.csv")
out <- lapply(HORIZONS, function(h) {
  d <- d0[d0$horizon == h, ]; d <- d[order(d$rate), ]
  d$cumw <- cumsum(d$weight) / sum(d$weight)
  lo <- max(d$rate[d$cumw <= 0.24]); hi <- min(d$rate[d$cumw >= 0.69])
  b <- aggregate(weight ~ bin, transform(d, bin = floor(rate)), sum)
  b$x <- b$bin + 0.5
  tail_of <- function(k) {
    t <- d[k, ]; t$contribution <- t$weight * t$rate
    t <- t[order(-abs(t$contribution)), ][seq_len(min(8, nrow(t))), ]
    data.frame(category = clean_category(t$category), change = r6(t$rate),
               weight = r6(100 * t$weight), contribution = r6(t$contribution))
  }
  m <- s[s$horizon == h & s$date == d$month[1], ]
  list(horizon = h, month = d$month[1], lo_cut = r6(lo), hi_cut = r6(hi),
       bins = data.frame(x = b$x, w = r6(b$weight), kept = b$x >= lo & b$x <= hi),
       low_tail = tail_of(d$rate < lo), high_tail = tail_of(d$rate > hi),
       n_low = sum(d$rate < lo), n_high = sum(d$rate > hi), n = nrow(d),
       markers = setNames(as.list(r6(m$value)), m$measure))
})
emit_json(out)
