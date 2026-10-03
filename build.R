#!/usr/bin/env Rscript
# Build the static site in docs/ (GitHub Pages serves docs/ on main):
#   docs/        the Shiny app, exported with shinylive
#   docs/proto/  the Observable Framework prototype (site/dist), if it has been built
#
#   Rscript build.R
#
# Run after compute/ has refreshed artifacts/ and app/data/ (refresh.sh does both,
# and builds site/ first).

if (!requireNamespace("shinylive", quietly = TRUE)) {
  stop("shinylive is not installed. Run: install.packages('shinylive')")
}

message("Exporting app/ -> docs/ (this bundles webR assets; first run downloads them) ...")
shinylive::export("app", "docs")

# Framework prototype: copy the built static site to docs/proto/ (relative paths,
# so it works under any subfolder). Replaced wholesale so stale hashed files go.
if (dir.exists("site/dist")) {
  unlink("docs/proto", recursive = TRUE)
  dir.create("docs/proto")
  file.copy(list.files("site/dist", full.names = TRUE, all.files = TRUE, no.. = TRUE),
            "docs/proto", recursive = TRUE)
  message("Copied site/dist -> docs/proto (", length(list.files("docs/proto", recursive = TRUE)), " files)")
}

# GitHub Pages must not run Jekyll: it would hide shinylive's and Framework's
# underscore-prefixed folders (_npm, _file, _observablehq).
file.create(file.path("docs", ".nojekyll"))

message("\nDone. Commit and push:")
message("  git add -A && git commit -m 'Rebuild dashboard' && git push")
