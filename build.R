#!/usr/bin/env Rscript
# Export the Shiny app in app/ to a static shinylive site in docs/.
# GitHub Pages serves docs/ on the main branch (Settings > Pages > /docs).
#
#   Rscript build.R
#
# Run after refresh_dashboard.R (in the pipeline repo) has updated app/data/.

if (!requireNamespace("shinylive", quietly = TRUE)) {
  stop("shinylive is not installed. Run: install.packages('shinylive')")
}

message("Exporting app/ -> docs/ (this bundles webR assets; first run downloads them) ...")
shinylive::export("app", "docs")

# GitHub Pages must not run Jekyll over the shinylive assets.
file.create(file.path("docs", ".nojekyll"))

message("\nDone. Commit and push:")
message("  git add -A && git commit -m 'Rebuild dashboard' && git push")
