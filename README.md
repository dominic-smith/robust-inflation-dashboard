# Robust Measures of Inflation — public dashboard

An interactive, monthly-updated dashboard of robust (trimmed-mean and median)
inflation measures, based on Ocampo, Schoenle & Smith, *"Robustness of Robust
Measures of Inflation."*

It is a **static [shinylive](https://posit-dev.github.io/r-shinylive/) app**: the
Shiny app is compiled to WebAssembly and runs entirely in the visitor's browser,
served for free from GitHub Pages. There is no server to run or maintain, and no
usage limits. All data is precomputed — the app only reads small files shipped in
`app/data/`.

## Live site

`https://dominic-smith.github.io/robust-inflation-dashboard/` *(enable in
Settings → Pages → Deploy from branch → `main` / `docs`)*

## Repository layout

```
app/
  app.R                 # the Shiny app (UI + server)
  R/theme_dashboard.R   # shared palette + ggplot theme
  data/
    latest_series.csv   # precomputed headline series (tidy long)
    vintage.json        # data vintage + source note
build.R                 # shinylive::export("app", "docs")
docs/                   # generated static site (served by GitHub Pages)
```

The data-generating pipeline lives in a **separate private repo**
(`ExtendingTheRange_IJCB`). That repo's `code/refresh_dashboard.R` recomputes the
artifacts in `app/data/` and copies them here. This repo never contains raw data
or the estimation code.

## Monthly update

1. In the pipeline repo: drop the new BEA underlying-PCE vintage into
   `data/1_raw/`, run the live pipeline subset, then
   `Rscript code/refresh_dashboard.R` (writes into this repo's `app/data/`).
2. Here: `Rscript build.R`
3. `git add -A && git commit -m "Update: <month>" && git push`

GitHub Pages redeploys automatically on push.

## Local preview

```r
# from the repo root
shiny::runApp("app")     # runs the app natively (fast dev loop)
Rscript build.R          # produces the static site in docs/
```

## Status

Phase 1 — "Latest reading" tab (headline PCE, core PCE, Cleveland median, Dallas
trimmed mean). Planned: the range of equivalent trims, latest-month price-change
distribution, and the interactive robustness (trim-grid RMSE) explorer.
