# Shared helper for the R data loaders: locate the repo's artifacts/ folder
# (written and validated by compute/) regardless of the loader's working directory.
artifact <- function(file) {
  roots <- c("../artifacts", "../../artifacts", "../../../artifacts")
  hit <- Find(function(r) file.exists(file.path(r, file)), roots)
  if (is.null(hit)) stop("artifacts/", file, " not found; run ./refresh.sh first")
  read.csv(file.path(hit, file), stringsAsFactors = FALSE)
}
# write CSV to stdout (Framework captures it as the loader's output)
emit <- function(df) write.csv(df, stdout(), row.names = FALSE, quote = TRUE)
