# Cell-edge segments enclosing the trims with DM p >= 0.01 vs the best trim (all
# categories), per sample x trend measure — the outline on the paper's bias figure.
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
dm <- artifact("heatmap_dm.csv")
segs <- do.call(rbind, lapply(split(dm, list(dm$sample, dm$target), drop = TRUE), function(d) {
  c <- d[is.na(d$p) | d$p >= 0.01, ]; key <- paste(c$lb, c$beta); has <- function(a, b) paste(a, b) %in% key
  l <- c$lb; b <- c$beta
  f <- function(k, x1, x2, y1, y2) if (any(k)) data.frame(x1 = x1[k], x2 = x2[k], y1 = y1[k], y2 = y2[k])
  s <- rbind(f(!has(l + 1, b), l + .5, l + .5, b - .5, b + .5), f(!has(l - 1, b), l - .5, l - .5, b - .5, b + .5),
             f(!has(l, b + 1), l - .5, l + .5, b + .5, b + .5), f(!has(l, b - 1), l - .5, l + .5, b - .5, b - .5))
  cbind(sample = d$sample[1], target = d$target[1], s)
}))
emit(segs)
