# Shared helpers for the R data loaders and the Overview page loader.
#
# The loaders are the site's compute layer at build time: they read the validated
# CSVs in ../artifacts (written by compute/ and checked by validate_refresh.R) and do
# every derived calculation, so the browser only filters and draws.
#
# Loaders round to 6 decimals; pages format for display. Rounding earlier (2-3
# decimals) double-rounds displayed values (0.7352 -> 0.735 -> "0.73").

artifact <- function(file) {
  roots <- c("../artifacts", "../../artifacts", "../../../artifacts")
  hit <- Find(function(r) file.exists(file.path(r, file)), roots)
  if (is.null(hit)) stop("artifacts/", file, " not found; run ./refresh.sh first")
  if (grepl("\\.json$", file)) return(jsonlite::fromJSON(file.path(hit, file)))
  read.csv(file.path(hit, file), stringsAsFactors = FALSE)
}

# Value of a --name=value argument (Framework passes [name] route params this way)
param <- function(name) {
  a <- grep(paste0("^--", name, "="), commandArgs(TRUE), value = TRUE)
  if (!length(a)) stop("missing --", name, "=")
  sub(paste0("^--", name, "="), "", a[1])
}

# Write to stdout, which Framework captures as the loader's output
emit <- function(df) write.csv(df, stdout(), row.names = FALSE, quote = TRUE, na = "")
emit_json <- function(x) cat(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 6, dataframe = "rows", na = "null"))

r6 <- function(x) round(x, 6)

# BEA product names carry footnote / line markers such as "Physician services (44)"
clean_category <- function(x) trimws(sub("\\s*\\(\\d+\\)\\s*$", "", trimws(x)))

ROBUST <- c("Core PCE", "Median PCE", "Trimmed-mean PCE")
HORIZONS <- c("1m", "3m", "12m")
