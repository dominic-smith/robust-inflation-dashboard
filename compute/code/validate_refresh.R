# Pre-push checks for the monthly refresh. Run from compute/code/ after
# export_artifacts.R (refresh.sh does this). Stops on a hard failure; prints the
# latest numbers for review.
#
#   1. Headline and core 12m must equal FRED's official PCEPI / PCEPILFE.
#   2. Every BEA line must carry the same name as the static classification
#      (BEA's late-September annual update can renumber detailed lines).
#   3. The trimmed mean's gap to the official Dallas series should stay small.

suppressPackageStartupMessages({library(dplyr); library(readr)})

s <- read_csv("../../artifacts/series_h.csv", show_col_types = FALSE) |> filter(horizon == "12m")
fred <- function(id, tries = 3) {
  url <- sprintf("https://fred.stlouisfed.org/graph/fredgraph.csv?id=%s", id)
  tmp <- tempfile(fileext = ".csv")
  for (i in seq_len(tries)) {               # curl over HTTP/1.1: R's own HTTP/2 client flakes on FRED
    ok <- tryCatch(utils::download.file(url, tmp, method = "curl", quiet = TRUE,
                                        extra = "--http1.1 --max-time 30") == 0,
                   error = function(e) FALSE, warning = function(w) FALSE)
    if (ok && file.size(tmp) > 100) break
    Sys.sleep(2)
  }
  if (!ok) stop("Could not download ", id, " from FRED after ", tries, " tries.")
  x <- read_csv(tmp, show_col_types = FALSE)
  names(x) <- c("date", "v"); x
}
yoy <- function(x) x |> arrange(date) |> mutate(v = (v / lag(v, 12) - 1) * 100)

# 1. headline / core vs FRED -------------------------------------------------
for (m in list(c("Headline PCE", "PCEPI"), c("Core PCE", "PCEPILFE"))) {
  f <- yoy(fred(m[2]))
  j <- inner_join(s |> filter(measure == m[1]), f, by = "date") |> filter(date >= max(date) - 365)
  d <- max(abs(j$value - j$v), na.rm = TRUE)
  message(sprintf("[1] %-12s vs FRED %-8s last 12m: max|diff| = %.3f pp", m[1], m[2], d))
  if (d > 0.01) stop(m[1], " does not match FRED ", m[2], " — check the BEA line mapping before pushing.")
}

# 2. BEA line names vs static classification ----------------------------------
d01 <- readRDS("../data/2_processed/d01m_pce_all_M.rds") |> distinct(line, product_name, name)
norm <- function(x) gsub("[^a-z]", "", tolower(trimws(x)))
mm <- d01[norm(d01$product_name) != norm(d01$name), ]
message(sprintf("[2] category lines: %d, name mismatches vs classification: %d", nrow(d01), nrow(mm)))
if (nrow(mm) > 0) { print(head(mm, 10)); stop("BEA lines no longer match category_definitions — classification needs updating.") }

# 3. trimmed mean vs official Dallas -------------------------------------------
dal <- fred("PCETRIM12M159SFRBDAL")
j <- inner_join(s |> filter(measure == "Dallas trimmed mean"), dal, by = "date") |> filter(date >= max(date) - 365)
g <- mean(abs(j$value - j$v), na.rm = TRUE)
message(sprintf("[3] trimmed mean vs official Dallas, last 12m: mean|gap| = %.3f pp (historically ~0.05)", g))
if (g > 0.2) warning("Trimmed-mean gap to official Dallas is unusually large — investigate before pushing.")

# Latest numbers for review ----------------------------------------------------
last2 <- sort(unique(s$date), decreasing = TRUE)[2:1]
tab <- s |> filter(date %in% last2) |> mutate(m = format(date, "%b %Y")) |>
  select(measure, m, value) |> tidyr::pivot_wider(names_from = m, values_from = value)
band <- read_csv("../../artifacts/best_trims_band.csv", show_col_types = FALSE) |>
  filter(target == "c_0_37", sample == "long") |> filter(date == max(date))
message("\nLatest 12-month readings:"); print(as.data.frame(tab), digits = 3, row.names = FALSE)
message(sprintf("Best-trims range (current trend, 1970-2024 set), %s: %.2f-%.2f%%, set mean %.2f%%",
                format(band$date, "%b %Y"), band$lo, band$hi, band$mean))
