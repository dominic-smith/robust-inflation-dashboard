# Export dashboard artifacts from the computed pipeline outputs into app/data/.
# Run with the working directory at compute/code/ (after run_compute.R).
# Writes only into ../../app/data.
#
# Produces horizon-aware series (1m / 3m annualized, 12m) by building a monthly
# price index for each measure and letting the app derive any horizon; plus the
# latest cross-sectional distribution at each horizon (for the "what trimming
# removes" chart and the discarded-category list).

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr)})

APP_DATA <- normalizePath("../../app/data", mustWork = FALSE)
if (!dir.exists(APP_DATA)) dir.create(APP_DATA, recursive = TRUE)
stata_m_to_date <- function(m) { m <- as.integer(m); as.Date(sprintf("%d-%02d-01", 1960L + m %/% 12L, m %% 12L + 1L)) }
MEASURE_LEVELS <- c("Headline PCE", "Core PCE", "Cleveland median", "Dallas trimmed mean")
HORIZONS <- c(`1m` = 1L, `3m` = 3L, `12m` = 12L)

# --- monthly price index per measure (stata-month date -> level) -----------
top   <- readRDS("../data/2_processed/d01m_pce_all_top_M.rds")
allm  <- readRDS("../data/2_processed/d01m_pce_all_M.rds")
tm_dal <- readRDS("../data/2_processed/d20m_trimmed_mean_DAL_M_1_DAL_24_69.rds")
tm_cle <- readRDS("../data/2_processed/d20m_trimmed_mean_CLE_M_1_pas_50_50.rds")

# headline & core: BEA price-index levels; median & trimmed: chain the monthly change
idx_from_change <- function(df) {           # df: date, trimmed_mean_1 (monthly %)
  df <- df |> filter(!is.na(trimmed_mean_1)) |> arrange(date)
  # Match finish_trim's lagged cumprod: the level at month d excludes d's own
  # change, so the 12m change ties out to the paper's published series.
  r <- 1 + df$trimmed_mean_1 / 100
  tibble(date = df$date, idx = 100 * cumprod(c(1, head(r, -1))))
}
idx_list <- list(
  `Headline PCE`        = top  |> filter(line == 1)   |> distinct(date, idx = price_index),
  `Core PCE`            = allm |> filter(line == 372) |> distinct(date, idx = price_index),
  `Cleveland median`    = idx_from_change(tm_cle),
  `Dallas trimmed mean` = idx_from_change(tm_dal)
) |> lapply(function(d) arrange(filter(d, !is.na(idx)), date))

# annualized h-month change at each date (calendar lag h; NA if t-h absent)
hchange <- function(d, h) {
  lagidx <- d$idx[match(d$date - h, d$date)]
  ((d$idx / lagidx)^(12 / h) - 1) * 100
}
series_h <- bind_rows(lapply(names(idx_list), function(mz) {
  d <- idx_list[[mz]]
  bind_rows(lapply(names(HORIZONS), function(hn) {
    tibble(date = stata_m_to_date(d$date), measure = mz, horizon = hn,
           value = hchange(d, HORIZONS[[hn]]))
  }))
})) |> filter(!is.na(value)) |>
  mutate(measure = factor(measure, levels = MEASURE_LEVELS),
         horizon = factor(horizon, levels = names(HORIZONS)))
write_csv(series_h, file.path(APP_DATA, "series_h.csv"))

# --- latest-month cross-sectional distribution at each horizon -------------
# 1/3/12-month category price changes (Dallas set), weighted, most recent month.
rel_files <- c(`1m` = "d10m_relatives_DAL_M_1", `12m` = "d10m_relatives_DAL_M_12")
# 3-month uses the 12-month file's g_i_3 column (same rows carry g_i_1/g_i_3/g_i_12)
get_dist <- function(hn) {
  gi <- c(`1m` = "g_i_1", `3m` = "g_i_3", `12m` = "g_i_12")[[hn]]
  ann <- c(`1m` = 12, `3m` = 4, `12m` = 1)[[hn]]
  src <- if (hn == "1m") "d10m_relatives_DAL_M_1" else "d10m_relatives_DAL_M_12"
  d <- readRDS(paste0("../data/2_processed/", src, ".rds"))
  d <- d[!is.na(d[[gi]]) & !is.na(d$weight), ]
  last_m <- max(d$date[!is.na(d[[gi]])])
  d <- d[d$date == last_m, ]
  tibble(horizon = hn, month = stata_m_to_date(last_m),
         category = trimws(d$product_name),
         rate = ((d[[gi]] / 100)^ann - 1) * 100,   # annualized to match the series lever
         weight = d$weight) |> arrange(rate)
}
distribution_h <- bind_rows(lapply(names(HORIZONS), get_dist))
write_csv(distribution_h, file.path(APP_DATA, "distribution_h.csv"))

# --- validation: 12m from the index should match the paper's d22m ----------
chk <- series_h |> filter(horizon == "12m") |>
  mutate(dm = as.integer((as.integer(format(date, "%Y")) - 1960) * 12 + as.integer(format(date, "%m")) - 1))
agg <- readRDS("../data/3_done/d22m_agg_time_series.rds")
cmp <- agg |> transmute(dm = date, `Headline PCE` = agg_pce, `Core PCE` = core_pce,
                        `Cleveland median` = median_pce, `Dallas trimmed mean` = trimmed_mean) |>
  pivot_longer(-dm, names_to = "measure", values_to = "ref")
v <- chk |> inner_join(cmp, by = c("dm", "measure")) |> mutate(d = abs(value - ref))
message(sprintf("12m validation vs d22m: max|Δ|=%.4f  mean|Δ|=%.5f", max(v$d, na.rm=TRUE), mean(v$d, na.rm=TRUE)))

# --- vintage stamp ---------------------------------------------------------
vintage_date <- max(series_h$date[series_h$horizon == "12m"])
writeLines(sprintf(
  '{\n  "vintage_date": "%s",\n  "vintage_label": "%s",\n  "refreshed_at": "%s",\n  "source": "BEA underlying PCE detail (current vintage), author computation",\n  "n_categories": %d\n}\n',
  format(vintage_date, "%Y-%m-%d"), format(vintage_date, "%B %Y"),
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), sum(distribution_h$horizon == "12m")),
  file.path(APP_DATA, "vintage.json"))

message("Wrote series_h.csv (", nrow(series_h), " rows), distribution_h.csv (", nrow(distribution_h), " rows), through ", format(vintage_date, "%B %Y"))
