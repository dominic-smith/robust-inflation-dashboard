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
- **Best-trims range** — the paper's Figure 1, live: the band of 12-month inflation produced by every trim statistically equivalent to the best (DM test, 5%), with the set mean and the headline/median/trimmed-mean lines. Which trims are equivalent is a paper result; the trims themselves are recomputed on each month's data.
- **Measure disagreement** — the spread across core, median, and trimmed mean over time, with summary spreads by inflation regime.
- **Distribution** — the latest month's category price changes weighted by spending, showing (and listing by name) what the trimmed mean discards; plus the paper's Figure 2, the 10/24/50/69/90th percentiles of category price changes over time.
- **Robustness** — interactive trim-grid heatmap (α×β): RMSE relative to the best trim, DM-test equivalence with the best trim, or average bias (with the paper's DM p ≥ 0.01 outline); trend-measure / sample / category selectors and a reference-measure RMSE table. Paper vintage, not the live monthly series.
- **Download & methods** — the monthly series as CSV, plus method notes.

A global **horizon lever** (1-month / 3-month annualized / 12-month) drives Latest reading, Measure disagreement, and Distribution.

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
  data/dashboard.rds    the only data the app reads: all tables packed into one compressed file
artifacts/              human-readable CSVs of everything the app shows (committed, not shipped to the browser)
compute/                self-contained measure pipeline (reuses the paper's R code)
  code/
    ado/                pipeline helpers (Stata-compatible semantics, trim engine)
    1_cleaning/ 2_analysis/   01m load, 02m grouping, 10m relatives, 21m median, 22m combine
    download_bea.R      fetch the current BEA underlying detail
    run_compute.R       01m -> 22m, pruned to the four dashboard measures, + best-trims band
    best_trims_band.R   apply the paper's equivalent-trim sets to the current data
    export_artifacts.R  write horizon-aware CSVs to artifacts/
    pack_app_data.R     pack artifacts/ into app/data/dashboard.rds
    validate_refresh.R  pre-push checks (FRED match, BEA line alignment, Dallas gap)
  analytical/
    extract_heatmap.R   ONE-TIME/ANNUAL: extract the trim-grid RMSE surfaces, DM
                        p-values, and equivalent-trim sets from the paper's outputs
                        (NOT part of refresh.sh)
  data/1_raw/           static inputs: author classifications + equiv_sets.csv
                        (the BEA workbook is downloaded)
build.R                 shinylive::export("app", "docs")
refresh.sh              one-command monthly refresh
docs/                   generated static site (served by GitHub Pages)
```

The 51×51 optimal-trim grid, prediction/RMSE analysis, and heatmaps from the paper
are the *analytical layer* (a paper result, not monthly data). They power the
**Robustness** tab and are refreshed only by re-running `compute/analytical/extract_heatmap.R`
against the paper repo (annually, then `pack_app_data.R`), never by the monthly `refresh.sh`.

## JavaScript front-end prototype (`site/`)

An Observable Framework version of two tabs (Latest reading, Best-trims range) that
loads without WebAssembly R: ~270 KB compressed on a first visit vs ~53 MB for the
Shiny app. R remains the compute layer — `site/src/data/*.csv.R` are data loaders that
read the validated `artifacts/` CSVs at build time.

```bash
cd site
npm install          # once
npm run dev          # live preview at http://127.0.0.1:3000
npm run build        # static site in site/dist/ (deployable to Cloudflare or GitHub Pages)
```

## Load time

The app runs R in the visitor's browser (WebAssembly), so a first visit downloads the
R runtime (~36 MB) plus every R package the app loads. Keep `app/app.R` to
`shiny`, `ggplot2`, `dplyr` and base R: adding `tidyr` alone pulls in `stringi` (13 MB).
Repeat visits reuse the browser cache.

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

Validation:
- Headline and core match FRED's official PCE price indexes exactly.
- The best-trims band reproduces the paper's published band exactly for 1970–2018
  (all 12 trend-measure × sample sets); later gaps are BEA revisions.
- **Dating.** The median and trimmed mean are dated to the month of the price change
  they measure. The paper's pipeline (`finish_trim`) dates its 12-month median and
  trimmed mean one month later; the dashboard deliberately does not, so these two
  series sit one month earlier than the paper's published lines. Correctly dated,
  the trimmed mean tracks the official Dallas Fed series about twice as closely.
  The paper's trim evaluation uses monthly rates and is unaffected.
