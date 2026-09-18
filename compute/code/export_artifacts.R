# Export dashboard artifacts from the computed pipeline outputs into app/data/.
# Run with the working directory at compute/code/ (after run_compute.R).
# Writes only into ../../app/data — never touches the pipeline or the R&R repo.

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr)})

APP_DATA <- normalizePath("../../app/data", mustWork = FALSE)
if (!dir.exists(APP_DATA)) dir.create(APP_DATA, recursive = TRUE)

stata_m_to_date <- function(m) {
  m <- as.integer(m); as.Date(sprintf("%d-%02d-01", 1960L + m %/% 12L, m %% 12L + 1L))
}

MEASURE_LEVELS <- c("Headline PCE", "Core PCE", "Cleveland median", "Dallas trimmed mean")

agg <- readRDS("../data/3_done/d22m_agg_time_series.rds")

# --- 1. headline series (tidy long) ----------------------------------------
wide <- agg |>
  transmute(date = stata_m_to_date(date),
            `Headline PCE` = agg_pce, `Core PCE` = core_pce,
            `Cleveland median` = median_pce, `Dallas trimmed mean` = trimmed_mean)

series <- wide |>
  pivot_longer(-date, names_to = "measure", values_to = "value") |>
  filter(!is.na(value)) |>
  mutate(measure = factor(measure, levels = MEASURE_LEVELS))
write_csv(series, file.path(APP_DATA, "latest_series.csv"))

# --- 2. range band: min/max spread across the robust measures --------------
# Matches the paper's d31m_min_max (Figure B.1): the disagreement band across
# core, median, and trimmed mean. cat flags the inflation regime (0 low / 1 mid /
# 2 high) so the app can report the range in high- vs low-inflation months.
range_band <- agg |>
  transmute(date = stata_m_to_date(date), lo = min, hi = max, diff = diff, cat = cat) |>
  filter(!is.na(lo), !is.na(hi))
write_csv(range_band, file.path(APP_DATA, "range_band.csv"))

# --- 3. latest-month cross-sectional distribution --------------------------
# 12-month price change of each detailed PCE category (Dallas set), with its
# expenditure weight, for the most recent month. Illustrates what trimming removes.
rel <- readRDS("../data/2_processed/d10m_relatives_DAL_M_12.rds")
last_m <- max(rel$date[!is.na(rel$g_i_12)])
dist <- rel |>
  filter(date == last_m, !is.na(g_i_12), !is.na(weight)) |>
  transmute(category = product_name, rate = g_i_12 - 100, weight = weight) |>
  arrange(rate)
write_csv(dist, file.path(APP_DATA, "distribution.csv"))

# --- 4. wide download table ------------------------------------------------
write_csv(wide, file.path(APP_DATA, "series_download.csv"))

# --- 5. vintage stamp ------------------------------------------------------
vintage_date <- max(wide$date)
vintage_label <- format(vintage_date, "%B %Y")
dist_label <- format(stata_m_to_date(last_m), "%B %Y")
writeLines(sprintf(
  '{\n  "vintage_date": "%s",\n  "vintage_label": "%s",\n  "dist_label": "%s",\n  "refreshed_at": "%s",\n  "source": "BEA underlying PCE detail (current vintage), author computation",\n  "n_categories": %d\n}\n',
  format(vintage_date, "%Y-%m-%d"), vintage_label, dist_label,
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), nrow(dist)),
  file.path(APP_DATA, "vintage.json"))

message("Artifacts written to ", APP_DATA)
message("  series ", nrow(series), " rows, through ", vintage_label,
        "; distribution ", nrow(dist), " categories (", dist_label, ")")
