# Median PCE — dashboard copy of 2_analysis/21m-median_pce.do.
# Function bodies are identical to the paper's 21m; only the bottom execution
# block is pruned to the single median run the dashboard's 22m consumes
# (d21m_medianchain_CLE_M_1). The paper also computes CLE/DAL/group-4 medians at
# other lags for its prediction analysis — not needed here.

# Find the observation whose cumulative weight crosses `thresh` in the
# date-sorted distribution of g_i_`lag` (weighted percentile, Stata-style).
calculate_moment_21m <- function(thresh, freq, group, lag) {
  p <- stata_round(thresh * 100)
  df <- read_proc(paste0("d10m_relatives_", group, "_", freq, "_", lag))
  g <- paste0("g_i_", lag)

  out <- df |>
    arrange(date, .data[[g]], line) |>
    group_by(date) |>
    mutate(sum = stata_sum(weight),
           sum_prev = dplyr::lag(sum),
           first = (sum_prev < thresh) | is.na(sum_prev),
           next_ = sum >= thresh) |>
    ungroup() |>
    filter(first & next_ & !is.na(first)) |>
    distinct(date, .keep_all = TRUE)

  out <- out |> select(date, !!paste0("p", p) := all_of(g), line, period,
                       !!paste0("cum", p) := sum)
  write_temp(out, paste0("d21m_p", p))
  out
}

calculate_moments_21m <- function(freq, group, lag) {
  moments <- c(0.01, 0.1, 0.24, 0.25, 0.5, 0.69, 0.75, 0.9, 0.99)
  dist <- NULL
  for (m in moments) {
    res <- calculate_moment_21m(m, freq, group, lag)
    if (is.null(dist)) {
      dist <- res
    } else {
      dist <- full_join(dist, select(res, -line, -period), by = "date") |> arrange(date)
    }
  }
  write_proc(dist, paste0("d21m_distribution_", group, "_", freq, "_", lag))
  dist
}

# 12-month geometric chaining of the monthly median (positional, date-sorted)
median_pce_chain <- function(p50) {
  p <- p50 / 100
  temp <- p
  for (k in 1:11) temp <- temp * dplyr::lag(p, k)
  temp[is.na(dplyr::lag(p, 11))] <- NA
  (temp - 1) * 100
}

load_official <- function() {
  off <- readr::read_csv("../data/1_raw/trimmed_mean and median.csv",
                         show_col_types = FALSE) |>
    rename_with(~ gsub("[^a-z0-9_]", "", tolower(.x))) |>
    select(-date) |>
    mutate(date = tm(year, month))
  write_raw(off, "d21m_official_targets")
}

median_inflation <- function(freq, group, lag, chain = FALSE) {
  dist <- calculate_moments_21m(freq, group, lag) |> arrange(date)
  if (chain) {
    message("Chaining")
    p50 <- median_pce_chain(dist$p50)
  } else {
    p50 <- dist$p50 - 100
  }
  out <- data.frame(date = dist$date, median_pce = p50)
  write_proc(out, paste0("d21m_median", if (chain) "chain" else "", "_",
                         group, "_", freq, "_", lag))
}

# --- dashboard execution (pruned) ------------------------------------------
load_official()
median_inflation(freq = "M", group = "CLE", lag = 1, chain = TRUE)
