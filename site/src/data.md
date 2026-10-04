---
title: Data and methods
---

```js
import {fmt, MEASURES, HORIZONS, horizonText} from "./components/theme.js";
import {segmented} from "./components/controls.js";
const downloads = {"12m": FileAttachment("data/downloads/12m.csv"), "3m": FileAttachment("data/downloads/3m.csv"), "1m": FileAttachment("data/downloads/1m.csv")};
const files = {"12m": FileAttachment("data/series/12m.csv"), "3m": FileAttachment("data/series/3m.csv"), "1m": FileAttachment("data/series/1m.csv")};
```

<p class="eyebrow">Data and methods</p>

# Data, definitions and sources

## Download

```js
const horizonInput = segmented(HORIZONS, {label: "Change over", value: "12m", key: "rrm-horizon"});
display(html`<div class="controls">${horizonInput}</div>`);
const horizon = Generators.input(horizonInput);
```

```js
const series = files[horizon].csv({typed: true});
```

```js
const index = new Map(series.map((d) => [`${d.measure}|${+d.date}`, d.value]));
const months = [...new Set(series.map((d) => +d.date))].sort((a, b) => b - a).slice(0, 12).map((t) => new Date(t));
display(html`<p>${[...HORIZONS].map(([label, h]) => html`<a class="download" href=${downloads[h].href} download=${`robust_inflation_${h}.csv`}>${label} CSV</a>`)}
  <span class="muted">Monthly, 1959 to the latest month: the four measures, ${horizonText[horizon]} shown below.</span></p>`);
```

<div class="card">
  <h3>Latest 12 months: ${horizonText[horizon]}</h3>
  <table>
    <thead><tr><th>Month</th>${MEASURES.map((m) => html`<th class="num">${m}</th>`)}</tr></thead>
    <tbody>${months.map((t) => html`<tr><td>${fmt.ym(t)}</td>${MEASURES.map((m) => html`<td class="num">${index.get(`${m}|${+t}`)?.toFixed(2) ?? "–"}</td>`)}</tr>`)}</tbody>
  </table>
</div>

## What the measures are

- **Headline PCE inflation**: the change in BEA's price index for all personal consumption expenditures.
- **Core PCE inflation**: the same index excluding food and energy.
- **Median PCE inflation**: each month, the roughly 180 detailed spending categories are sorted by their price change and weighted by their share of spending; the median is the change at the middle of that distribution. This follows the Cleveland Fed's approach.
- **Trimmed-mean PCE inflation**: the same sorted distribution with the lowest-changing 24% and highest-changing 31% of spending set aside, and the rest averaged. This follows the Dallas Fed's definition.
- **Best-trims range**: the paper evaluates all 2,601 combinations of how much to trim from each end (0–50% from each). For each measure of trend inflation it identifies the set of trims whose forecast errors are statistically indistinguishable from the best trim's (Diebold–Mariano test, 5% level). The range is the lowest to highest 12-month rate across that set; its average is the "best-trims average".
- **Horizons**: the 12-month change compares a month with the same month a year earlier. The 3- and 1-month changes are expressed at annual rates; they react sooner but are noisier.

## Sources and computation

- Price indexes and spending come from BEA's underlying detail tables for personal consumption expenditures (Tables 2.4.4U and 2.4.5U), downloaded each month. The latest release is used in full, so earlier months reflect BEA's revisions, including its annual updates.
- Headline and core inflation are BEA's published aggregates, checked against FRED each month. The median and trimmed mean are computed by the authors from the detailed categories. They follow the Federal Reserve Banks' published definitions but are not the official series, and differ from them slightly.
- Each measure is dated to the month of the price change it measures.
- Which trims make up each best-trims set, and the robustness results, come from the paper's evaluation and are fixed at its data vintage. The trims themselves are recomputed on every new data release.

## Reference

Ocampo, Schoenle and Smith, “Robustness of Robust Measures of Inflation,” *International Journal of Central Banking*, forthcoming.

<p class="footnote">This site is an independent research companion to the paper. It is not an official statistic, and it does not represent the views of the Bureau of Labor Statistics, the Federal Reserve System, or any other institution.</p>

<style>
a.download { display: inline-block; margin: 0 0.5rem 0.5rem 0; padding: 6px 14px; border-radius: 999px; border: 1px solid var(--ring); background: var(--surface); text-decoration: none; font-weight: 600; font-size: 13.5px; }
a.download:hover { border-color: var(--accent); }
</style>
