# Replicates the Stata `file write` blocks that emit \Copy{name}{value} lines
# into code/figures/XXm-numbers.tex for the paper's in-text numbers.

open_numbers <- function(file, append = FALSE) {
  if (!append && file.exists(file)) file.remove(file)
  if (!file.exists(file)) file.create(file)
  invisible(file)
}

write_copy <- function(file, name, value, comment = NULL) {
  line <- paste0("\\Copy{", name, "}{", value, "}")
  if (!is.null(comment)) line <- paste0(line, " % ", comment)
  cat(line, "\n", sep = "", file = file, append = TRUE)
}
