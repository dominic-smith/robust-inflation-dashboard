# Robust Measures of Inflation — public dashboard

An interactive, monthly-updated dashboard of robust (trimmed-mean and median)
inflation measures, based on Ocampo, Schoenle & Smith, *"Robustness of Robust
Measures of Inflation."*

It is a **static [shinylive](https://posit-dev.github.io/r-shinylive/) app**: the
Shiny app is compiled to WebAssembly and runs entirely in the visitor's browser,
served for free from GitHub Pages. No server, no maintenance, no usage limits.

**This repository is fully self-contained.** It downloads the current BEA
underlying-PCE vintage and recomputes the measures itself — it reads nothing from
the (frozen) paper/R&R repository. Because BEA revises history, numbers here
reflect the current vintage and differ slightly from the published paper; this is
a living companion to the paper, not its archival record.

## Live site

https://dominic-smith.com/robust-inflation-dashboard/

## Tabs

- **Latest reading** — the four measures now (headline PCE, core PCE, median PCE, trimmed mean), value cards + trend.
- **The range** — the disagreement band across the robust measures over time, with summary spreads by inflation regime.
- **Distribution** — the latest month's category price changes weighted by spending, showing (and listing by name) what the trimmed mean discards.
- **Robustness** — interactive trim-grid RMSE heatmap (α×β) with trend-measure / sample / category selectors and a reference-measure RMSE table. Analytical layer from the paper's prediction analysis (paper vintage), not the live monthly series.
- **Download & methods** — the monthly series as CSV, plus method notes.

A global **horizon lever** (1-month / 3-month annualized / 12-month) drives the three live-series tabs.

## Monthly update

```bash
./refresh.sh                    # download BEA -> compute -> export -> rebuild
git add -A && git commit -m "Update: $(date +%Y-%m)" && git push
```

GitHub Pages redeploys automatically on push.

## Repository layout

```
app/                    the Shiny app (compiled to docs/ by build.R)
  app.R
  R/theme_dashboard.R
  data/                 precomputed artifacts the app reads (small CSVs + vintage.json)
compute/                self-contained measure pipeline (reuses the paper's R code)
  code/
    ado/                pipeline helpers (Stata-compatible semantics, trim engine)
    1_cleaning/ 2_analysis/   01m load, 02m grouping, 10m relatives, 21m median, 22m combine
    download_bea.R      fetch the current BEA underlying detail
    run_compute.R       01m -> 22m, pruned to the four dashboard measures
    export_artifacts.R  write horizon-aware app/data/ from the computed series
  analytical/
    extract_heatmap.R   ONE-TIME/ANNUAL: extract the trim-grid RMSE surfaces from
                        the paper's prediction outputs (NOT part of refresh.sh)
  data/1_raw/           static author-classification inputs (BEA workbook is downloaded)
build.R                 shinylive::export("app", "docs")
refresh.sh              one-command monthly refresh
docs/                   generated static site (served by GitHub Pages)
```

The 51×51 optimal-trim grid, prediction/RMSE analysis, and heatmaps from the paper
are the *analytical layer* (a paper result, not monthly data). They power the
**Robustness** tab and are refreshed only by re-running `compute/analytical/extract_heatmap.R`
against the paper repo (annually), never by the monthly `refresh.sh`.

## Local development

```r
shiny::runApp("app")     # native, fast dev loop (no WebAssembly)
Rscript build.R          # produce the static site in docs/
```

## Data provenance

- **Headline & core PCE** — BEA aggregate price indexes (12-month change).
- **Median PCE & trimmed mean** — computed from the ~180 detailed PCE categories
  using the paper's methodology (weight each category's price change by spending
  share; take the weighted middle, or trim the weighted tails and average).

Validated against the paper: at the Feb-2024 overlap the recomputed series match
the published series to ~0.005 pp on average (residual differences are BEA data
revisions), and the recomputed trimmed mean tracks the official Dallas Fed series.
