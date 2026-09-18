# Core trimmed-mean machinery shared by 20m-trimmed_mean.R and 20z-gen_las_pas.R.
# Faithful port of the `trimmed_mean` program (identical in both .do files):
# everything that does not depend on (lb, ub) is precomputed once in trim_prep(),
# so the 51x51 grid reuses one sorted/cumulated dataset.

trim_prep <- function(group, freq, lag, weights) {
  df <- read_proc(paste0("d10m_relatives_", group, "_", freq, "_", lag)) |>
    arrange(line, date) |>
    group_by(line) |>
    mutate(dp = (dplyr::lead(price_index, lag) - price_index) / price_index) |>
    ungroup()

  if (weights == "las") {
    df <- df |>
      group_by(date) |>
      mutate(wts = real_spending / stata_total(real_spending)) |>
      ungroup()
  } else if (weights == "pas") {
    df <- df |>
      arrange(line, date) |>
      group_by(line) |>
      mutate(wts = dplyr::lead(weight, lag)) |>
      ungroup()
  } else {  # Dallas: average of forward and current expenditure shares
    df <- df |>
      group_by(line) |>
      mutate(wts1 = dplyr::lead(real_spending, lag) * price_index,
             wts2 = real_spending * price_index) |>
      group_by(date) |>
      mutate(wts1 = wts1 / stata_total(wts1),
             wts2 = wts2 / stata_total(wts2)) |>
      ungroup() |>
      mutate(wts = 0.5 * (wts1 + wts2))
  }

  # sort date dp (NA dp last, line as deterministic tiebreak); cum within date
  df <- df |>
    arrange(date, dp, line) |>
    group_by(date) |>
    mutate(cum = stata_sum(wts),
           cum_prev = dplyr::lag(cum)) |>
    ungroup()

  dates <- unique(df$date)  # sorted
  list(
    date     = df$date,
    date_id  = match(df$date, dates),
    dates    = dates,
    first    = c(TRUE, df$date[-1] != df$date[-nrow(df)]),
    line     = df$line,
    g_i_1    = df$g_i_1,
    dp       = df$dp,
    wts      = df$wts,
    cum      = df$cum,
    cum_prev = df$cum_prev,
    lag      = lag
  )
}

# One (lb, ub) combo on precomputed data. Returns list(result = final tibble,
# lines = tibble for the d20m_lines_* file).
trim_combo <- function(p, lb, ub) {
  lbv <- lb / 100
  ubv <- ub / 100
  t1 <- p$cum >= lbv
  t2 <- p$cum > ubv
  t1p <- c(NA, t1[-length(t1)]); t1p[p$first] <- NA
  t2p <- c(NA, t2[-length(t2)]); t2p[p$first] <- NA

  m1 <- rep(NA_real_, length(t1))
  # first obs above lb (and below ub) absorbs the mass from lb up to its cum
  c1 <- t1 & !t2 & (is.na(t1p) | !t1p)
  m1[c1] <- p$cum[c1] - lbv
  # strictly interior obs get their own weight
  c2 <- t1 & !t2 & !c1
  m1[c2] <- p$wts[c2]
  # single obs covering the entire interval gets weight 1 (Stata quirk kept as-is)
  c3 <- t1 & t2 & !is.na(t2p) & !t2p & !is.na(t1p) & !t1p
  m1[c3] <- 1
  # obs that crosses the top: mass from previous cum up to ub
  c4 <- t1 & t2 & !c3 & !is.na(t2p) & !t2p
  m1[c4] <- ubv - p$cum_prev[c4]

  keep <- !is.na(m1)
  # normalize within date and aggregate m1 * dp
  tot1 <- rowsum(ifelse(keep, m1, 0), p$date_id, reorder = FALSE)[, 1]
  tot1[tot1 == 0] <- NA_real_  # Stata: division by zero -> missing, not Inf
  contrib <- (m1 / tot1[p$date_id]) * p$dp
  m1_agg <- rowsum(ifelse(is.na(contrib), 0, contrib), p$date_id, reorder = FALSE)[, 1]
  # max/min of dp among trimmed-in obs (NA when none)
  dp_in <- ifelse(keep, p$dp, NA_real_)
  suppressWarnings({
    max_agg <- rowsum_max(dp_in, p$date_id, length(p$dates))
    min_agg <- -rowsum_max(-dp_in, p$date_id, length(p$dates))
  })

  res <- finish_trim(p$dates, m1_agg, min_agg, max_agg, p$lag)
  lines <- list(date = p$date[keep], line = p$line[keep], g_i_1 = p$g_i_1[keep])
  list(result = res, lines = lines)
}

# group max ignoring NA, NA for all-NA groups (collapse (max) semantics)
rowsum_max <- function(x, g, ng) {
  ok <- !is.na(x)
  out <- rep(NA_real_, ng)
  if (any(ok)) {
    mx <- tapply(x[ok], g[ok], max)
    out[as.integer(names(mx))] <- mx
  }
  out
}

# The post-collapse block: drop last date, chain (lag 1) or relabel (lag n).
# For lag 1: build a price index, convert to YoY, store monthly change in trimmed_mean_1.
# For lag n>1: dp is already an n-month change; shift date forward by n rows to the
# end of the window and store the raw n-month percent change in trimmed_mean.
finish_trim <- function(dates, m1, min_d, max_d, lag) {
  n <- length(dates) - 1L  # drop if _n == _N
  dates <- dates[1:n]; m1 <- m1[1:n]; min_d <- min_d[1:n]; max_d <- max_d[1:n]

  if (lag == 1) {
    tm_index <- 100 * cumprod(c(1, 1 + m1[-n]))
    chg <- tm_index / dplyr::lag(tm_index, 12) * 100 - 100
    data.frame(date = dates + 1,
               trimmed_mean = chg,
               trimmed_mean_1 = m1 * 100,
               min = min_d * 100,
               max = max_d * 100)
  } else {
    new_date <- dplyr::lead(dates, lag)  # shift to end of the n-month window
    keep <- !is.na(new_date)
    data.frame(date = new_date[keep],
               trimmed_mean = m1[keep] * 100,
               trimmed_mean_1 = 0,
               min = min_d[keep],
               max = max_d[keep])
  }
}

# Full single run, mirroring one `trimmed_mean, ...` call (writes both outputs).
# write_lines = FALSE skips the d20m_lines_* file (only 3 specific ones are ever
# read downstream; the 5,200 grid ones would be ~GBs of dead weight).
trimmed_mean_single <- function(group, freq, lag, weights, lb, ub,
                                prep = NULL, write_lines = TRUE) {
  if (is.null(prep)) prep <- trim_prep(group, freq, lag, weights)
  out <- trim_combo(prep, lb, ub)
  stub <- paste(group, freq, lag, weights, lb, ub, sep = "_")
  if (write_lines)
    saveRDS(as.data.frame(out$lines), proc_path(paste0("d20m_lines_", stub)), compress = FALSE)
  saveRDS(out$result, proc_path(paste0("d20m_trimmed_mean_", stub)), compress = FALSE)
  invisible(out$result)
}
