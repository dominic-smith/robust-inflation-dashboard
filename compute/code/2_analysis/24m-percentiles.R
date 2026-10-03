# Percentiles of the price-change distribution — dashboard copy of 2_analysis/24m-percentiles.R.
# Function bodies are identical to the paper's; the run calls below cover the Dallas
# category set at the dashboard's three horizons (the paper runs DAL and group 4 at lag 1).
# Like 21m but: negative weights dropped and renormalized, g_i centered at 0, no 1/99.

calculate_moment_24m <- function(thresh, freq, group, lag) {
  p <- stata_round(thresh * 100)
  g <- paste0("g_i_", lag)

  df <- read_proc(paste0("d10m_relatives_", group, "_", freq, "_", lag)) |>
    filter(!(weight < 0) | is.na(weight)) |>   # drop if weight < 0 (NA kept)
    group_by(date) |>
    mutate(weight = weight / stata_total(weight)) |>
    ungroup() |>
    mutate(!!g := .data[[g]] - 100)

  out <- df |>
    arrange(date, .data[[g]], line) |>
    group_by(date) |>
    mutate(sum = stata_sum(weight),
           sum_prev = dplyr::lag(sum),
           first = (sum_prev < thresh) | is.na(sum_prev),
           next_ = sum >= thresh) |>
    ungroup() |>
    filter(first & next_) |>
    distinct(date, .keep_all = TRUE) |>
    select(date, !!paste0("p", p) := all_of(g), line, !!paste0("cum", p) := sum)

  write_temp(out, paste0("d24m_p", p))
  out
}

calculate_moments_24m <- function(freq, group, lag) {
  moments <- c(0.1, 0.24, 0.25, 0.5, 0.69, 0.75, 0.9)
  dist <- NULL
  for (m in moments) {
    res <- calculate_moment_24m(m, freq, group, lag)
    if (is.null(dist)) {
      dist <- res
    } else {
      dist <- full_join(dist, select(res, -line), by = "date") |> arrange(date)
    }
  }
  write_proc(dist, paste0("d24m_distribution_", group, "_", freq, "_", lag))
}

# --- dashboard execution: paper Figure 2 at each horizon ----------------------
for (lag in c(1, 3, 12)) calculate_moments_24m(freq = "M", group = "DAL", lag = lag)
