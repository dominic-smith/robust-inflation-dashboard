# Shared helper for the R data loaders: locate the repo's artifacts/ folder
# (written and validated by compute/) regardless of the loader's working directory.
artifact <- function(file) {
  roots <- c("../artifacts", "../../artifacts", "../../../artifacts")
  hit <- Find(function(r) file.exists(file.path(r, file)), roots)
  if (is.null(hit)) stop("artifacts/", file, " not found; run ./refresh.sh first")
  read.csv(file.path(hit, file), stringsAsFactors = FALSE)
}
# Loaders round to 6 decimals: pages format for display themselves, and rounding
# earlier (e.g. to 2-3 decimals) double-rounds displayed values (0.7352 -> 0.735 -> "0.73").
# write CSV to stdout (Framework captures it as the loader's output)
emit <- function(df) write.csv(df, stdout(), row.names = FALSE, quote = TRUE, na = "")
