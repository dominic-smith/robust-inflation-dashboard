# Combine headline/core/median/trimmed-mean series
# — translation of 2_analysis/22m-combine_measures.do

# Stata merge 1:1: union of dates; master values win on conflicting columns
merge_keep_master <- function(master, using) {
  new_cols <- c("date", setdiff(names(using), names(master)))
  full_join(master, using[new_cols], by = "date") |> arrange(date)
}

agg_pce_22m <- function(freq, lag) {
  df <- read_proc(paste0("d01m_pce_all_top_", freq)) |>
    filter(line == 1) |>
    select(date, agg_pce = !!paste0("g_i_", lag)) |>
    distinct() |>
    mutate(agg_pce = agg_pce - 100)
  write_temp(df, "d22m_agg_pce")
  df
}

core_pce_22m <- function(freq, lag) {
  df <- read_proc(paste0("d01m_pce_all_", freq)) |>
    filter(line == 372) |>
    select(date, core_pce = !!paste0("g_i_", lag)) |>
    mutate(core_pce = core_pce - 100)
  write_temp(df, "d22m_core_pce")
  df
}

combine_measures <- function() {
  read_temp("d22m_agg_pce") |>
    merge_keep_master(read_temp("d22m_core_pce")) |>
    merge_keep_master(read_proc("d20m_trimmed_mean_CLE_M_1_pas_50_50")) |>
    rename(median_pce = trimmed_mean) |>
    merge_keep_master(read_proc("d20m_trimmed_mean_DAL_M_1_DAL_24_69")) |>
    merge_keep_master(read_proc("d21m_medianchain_CLE_M_1"))
}

annualize <- function(x) ((x / 100 + 1)^12 - 1) * 100

combine_measures_1 <- function() {
  # `use g_i_1 date line` keeps all three columns; line and g_i_1 ride along
  df <- read_proc("d01m_pce_all_top_M") |>
    filter(line == 1) |>
    select(g_i_1, date, line) |>
    mutate(agg_pce = ((g_i_1 / 100)^12 - 1) * 100) |>
    merge_keep_master(read_temp("d22m_core_pce")) |>
    merge_keep_master(read_proc("d20m_trimmed_mean_CLE_M_1_pas_50_50")) |>
    rename(median_pce = trimmed_mean) |>
    mutate(trimmed_mean_1 = annualize(trimmed_mean_1)) |>
    rename(median_pce_1 = trimmed_mean_1) |>
    merge_keep_master(read_proc("d20m_trimmed_mean_DAL_M_1_DAL_24_69")) |>
    mutate(trimmed_mean_1 = annualize(trimmed_mean_1)) |>
    merge_keep_master(read_proc("d21m_medianchain_CLE_M_1"))
  df
}

# Stata comparisons treat missing as +infinity: . >= x is TRUE, x >= . is FALSE
geq_stata <- function(x, y) ifelse(is.na(x), TRUE, ifelse(is.na(y), FALSE, x >= y))

add_flags <- function(df, max_vars) {
  df <- df |>
    filter(date >= tm(1960, 1)) |>
    mutate(
      # missing agg_pce: `> 2.5` true but `< 5` false -> cat 1 skipped; `>= 5` true -> cat 2
      cat = case_when(is.na(agg_pce) | agg_pce >= 5 ~ 2,
                      agg_pce > 2.5 & agg_pce < 5 ~ 1,
                      TRUE ~ 0),
      core_higher = as.numeric(geq_stata(core_pce, agg_pce)),
      median_higher = as.numeric(geq_stata(median_pce, agg_pce)),
      trim_higher = as.numeric(geq_stata(trimmed_mean, agg_pce))) |>
    select(-min, -max)
  vals <- df[max_vars]
  df$max <- apply(vals, 1, stata_max)
  df$min <- apply(vals, 1, stata_min)
  df$diff <- df$max - df$min
  df
}

main_22m <- function() {
  agg_pce_22m("M", 12)
  core_pce_22m("M", 12)
  df <- combine_measures() |>
    add_flags(c("core_pce", "median_pce", "trimmed_mean"))
  write_done(df, "d22m_agg_time_series")
}

main2_22m <- function() {
  agg_pce_22m("M", 1)
  core_pce_22m("M", 1)
  df <- combine_measures_1() |>
    add_flags(c("median_pce_1", "trimmed_mean_1"))
  write_done(df, "d22m_agg_time_series_1")
}

main_22m()
main2_22m()
