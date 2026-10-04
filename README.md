# Robust Measures of Inflation

A monthly-updated public dashboard of robust US inflation measures (trimmed-mean
and median PCE) and of the range of underlying inflation supported by the best
trims, based on Ocampo, Schoenle and Smith, *"Robustness of Robust Measures of
Inflation"* (International Journal of Central Banking, forthcoming).

**Live:** https://dominic-smith.com/robust-inflation-dashboard/ (GitHub Pages, served from `docs/`)

The repository is self-contained: it downloads the current BEA vintage and recomputes
everything itself, reading nothing from the paper's (frozen) replication repository.
Because BEA revises history, figures reflect the current vintage and differ slightly
from the published paper. This is a living companion to the paper, not its archival
record, and not an official statistic.

## Monthly update

```bash
./refresh.sh     # download BEA -> compute -> export -> validate -> build -> browser test
git add -A && git commit -m "Update: $(date +%Y-%m)" && git push
```

`refresh.sh` stops if headline or core PCE do not match FRED exactly, if any BEA line
no longer matches the static category classification (BEA's late-September annual
update can renumber lines), or if any page fails its browser checks. Review the
printed numbers before pushing. To rebuild the site alone (for a design change), run
`./build.sh`, then `cd site && npm test`.

## How it is built

```
compute/   R. Downloads BEA's underlying PCE detail and recomputes the measures with the
           paper's own code (01m-24m), plus the best-trims band. Validates against FRED.
artifacts/ The validated outputs as CSV (committed). The only interface to the site.
site/      Observable Framework. R data loaders (src/data/*.R) and the Overview page
           loader (src/index.md.R) read artifacts/ at build time; pages are Markdown +
           Observable Plot. Output: site/dist.
docs/      The built static site (copied from site/dist by build.sh).
```

- **All numbers come from R.** The loaders compute every derived quantity (bands, bins,
  trim cut points, discarded lists, heatmap classes, the DM outline); the pages only
  filter and draw. `site/test/verify.mjs` recomputes key values independently from
  `artifacts/` and checks the rendered pages against them.
- **The paper's analytical layer** (the 51×51 trim grid, prediction/RMSE results, DM
  tests, bias) is fixed at the paper's vintage. `compute/analytical/extract_heatmap.R`
  extracts it from the paper repo once (annually at most), followed by `./build.sh`; the
  monthly refresh never touches it. The best-trims band *is* live: the paper fixes which
  trims are statistically tied with the best, and each month every one of them is
  recomputed on the new data.

## Pages

| Page | What it answers |
|---|---|
| Overview | Where underlying inflation is, against 2%, which way it is moving, what is driving headline |
| Underlying inflation range | The paper's Figure 1, live, for each trend measure and sample |
| The four measures | Headline, core, median, trimmed mean at 1, 3 and 12 months |
| What's driving it | This month's category price changes, what trimming removes, the paper's Figure 2 |
| Do the measures agree? | The spread across core, median and trimmed mean (App. Fig. B.1) |
| Why trimmed means are robust | Accuracy, statistical ties and bias for all 2,601 trims |
| Data and methods | Downloads, definitions, sources, disclaimer |

## Performance

- No WebAssembly, no web fonts (system sans), no third-party requests (the test fails on any).
- The Overview is rendered by R at build time: its numbers and narrative are plain
  HTML, visible before any JavaScript runs, and its charts use inline data.
- Each selection loads only its own data: one horizon, one trim set, one category set.
- The robustness heatmap is drawn as one raster image, not 2,601 SVG cells.
- Lightweight custom controls instead of the Inputs library.
- `site/static/_headers` marks content-hashed assets as immutable for Cloudflare Pages
  (GitHub Pages ignores it).

## Design

Colours follow the dataviz reference palette, validated with its `validate_palette.js`:
trimmed mean, median and core take categorical slots 1-3 (all-pairs CVD-safe in light
and dark mode); headline is the de-emphasis grey. The heatmaps use one blue ramp,
stronger = better. Every chart has a legend, direct labels, a crosshair tooltip and a
table view. Light and dark mode each have their own steps.

## Data notes

- **Dating.** The median and trimmed mean are dated to the month of the price change.
  The paper's pipeline (`finish_trim`) dates its 12-month median and trimmed mean one
  month later; the dashboard deliberately does not. The paper's trim evaluation uses
  monthly rates and is unaffected.
- **Names.** "Median PCE" and "Trimmed-mean PCE" are the authors' reconstructions
  (Cleveland Fed-style median; Dallas Fed 24/31 trim) and differ slightly from the
  official Federal Reserve series.
- **Validation.** Headline and core match FRED exactly; the trimmed mean tracks the
  official Dallas Fed series to about 0.04 pp; the live best-trims band reproduces the
  paper's published band exactly for 1970-2018; Figure 2 percentiles match the paper
  exactly for 1960-2018.

## Moving to Cloudflare Pages

Create a Pages project from this repository with no build command and build output
directory `docs`. The site uses relative paths, so it works at a root domain or a
subpath. The largest file is well under Cloudflare's 25 MiB limit. Remove
`<meta name="robots" content="noindex">` in `site/observablehq.config.js` if it
should be indexed.

## Local development

```bash
cd site && npm install       # once
npm run dev                  # live preview at http://127.0.0.1:3000
npm run build && npm test    # production build + browser checks (needs Chrome)
```
