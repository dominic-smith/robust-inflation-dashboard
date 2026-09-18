# Create price relatives per group/frequency/lag
# — translation of 2_analysis/10m-create_relatives.do

create_relatives <- function(freq, group, lag) {
  df <- read_proc(paste0("d01m_pce_all_top_", freq))
  grp <- read_proc(paste0("d02m_group", group))

  # merge with the group file: group 3 membership is by (y, line), others by line
  # (non-3 group files may carry an `id` column, which merges in as in Stata)
  if (group != "3") {
    df <- df |>
      left_join(mutate(grp, .matched = TRUE), by = "line") |>
      mutate(matched = !is.na(.matched)) |>
      select(-.matched)
  } else {
    df <- df |> mutate(matched = paste(y, line) %in% paste(grp$y, grp$line))
  }

  # weight recomputed within the group: spending / total group spending per date
  df <- df |>
    rename(temp_weight = weight) |>
    group_by(date) |>
    mutate(tot_spending = ifelse(matched, stata_total(spending[matched]), NA_real_)) |>
    ungroup() |>
    mutate(weight = ifelse(matched, spending / tot_spending, NA_real_))

  df <- df |>
    arrange(line, date) |>
    group_by(line) |>
    mutate(
      # positional [_n-lag] within line (dates are contiguous, equals calendar lag)
      w_lag = dplyr::lag(weight, lag),
      g     = .data[[paste0("g_i_", lag)]],
      # Geometric Mean/Tornqvist with average weights
      geo_mean = log(g) * (weight + w_lag) / 2,
      laspeyres = (g - 100) * w_lag,
      laspeyres_gini = g * w_lag,
      paasche = (g - 100) * weight,
      fischer_comp = (weight + w_lag) / 2 * (g - 100)) |>
    ungroup()

  # truth: aggregate (line 1) inflation, spread to all rows, scaled by lagged weight
  df <- df |>
    mutate(temp = ifelse(line == 1, g - 100, NA_real_)) |>
    group_by(date) |>
    mutate(truth = stata_max(temp)) |>
    ungroup() |>
    arrange(line, date) |>
    group_by(line) |>
    mutate(truth = dplyr::lag(weight, lag) * truth) |>
    ungroup() |>
    filter(matched) |>
    select(-matched, -w_lag, -g)  # temp stays, as in the .do file

  write_proc(df, paste0("d10m_relatives_", group, "_", freq, "_", lag))

  overall <- df |>
    group_by(date, y) |>
    summarise(across(c(geo_mean, laspeyres, paasche, fischer_comp, laspeyres_gini, truth),
                     stata_total), .groups = "drop") |>
    mutate(geo_mean = exp(geo_mean) - 100,
           fischer = sqrt(laspeyres * paasche)) |>
    filter(!is.na(truth), truth != 0)

  write_proc(overall, paste0("d10m_overall_", group, "_", freq, "_", lag))
}

main_10m <- function() {
  message("F: ", paste(GLOBALS$freqs, collapse = " "))
  message("G: ", paste(GLOBALS$groups, collapse = " "))
  for (f in GLOBALS$freqs) {
    for (group in GLOBALS$groups) {
      for (lag in lag_list(f)) {
        message("10m: ", f, " ", group, " ", lag)
        create_relatives(freq = f, group = group, lag = lag)
      }
    }
  }
  create_relatives(freq = "M", group = "CLE", lag = 1)
  create_relatives(freq = "M", group = "CLE", lag = 12)
  create_relatives(freq = "M", group = "DAL", lag = 12)
  create_relatives(freq = "M", group = "DAL", lag = 1)
}

main_10m()
