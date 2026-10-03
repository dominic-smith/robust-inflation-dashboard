# Latest-month cross-section per horizon: 1pp histogram bins of category price changes
# (spending-weighted), each flagged kept vs trimmed by the trimmed mean's 24/69 cut
# points, the cut points themselves, and the largest discarded categories in each tail.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
d0 <- artifact("distribution_h.csv")
out <- lapply(c("1m", "3m", "12m"), function(h) {
  d <- d0[d0$horizon == h, ]; d <- d[order(d$rate), ]
  d$cumw <- cumsum(d$weight) / sum(d$weight)
  lo <- max(d$rate[d$cumw <= 0.24]); hi <- min(d$rate[d$cumw >= 0.69])
  b <- aggregate(weight ~ bin, transform(d, bin = floor(rate)), sum)
  b$x <- b$bin + 0.5
  b$status <- ifelse(b$x >= lo & b$x <= hi, "Kept (averaged)", "Trimmed away")
  tl <- function(k) { t <- d[k, ]; t <- t[order(-t$weight), ][seq_len(min(8, sum(k))), ]
    data.frame(category = trimws(t$category), change = round(t$rate, 6), weight = round(100 * t$weight, 6)) }
  list(horizon = h, month = d$month[1], lo_cut = lo, hi_cut = hi,
       bins = data.frame(x = b$x, w = round(b$weight, 6), status = b$status),
       low_tail = tl(d$rate < lo), high_tail = tl(d$rate > hi),
       n_low = sum(d$rate < lo), n_high = sum(d$rate > hi))
})
cat(jsonlite::toJSON(out, auto_unbox = TRUE, digits = 6, dataframe = "rows"))
