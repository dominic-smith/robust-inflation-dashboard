---
title: Download & methods
---

```js
import {MEASURES, horizonInput, changeLabel} from "./components/style.js";
const series = FileAttachment("data/series.csv").csv({typed: true});
const files = {
  "1m": FileAttachment("data/downloads/robust_inflation_1m.csv"),
  "3m": FileAttachment("data/downloads/robust_inflation_3m.csv"),
  "12m": FileAttachment("data/downloads/robust_inflation_12m.csv")
};
```

# Download the data

<p class="muted">Monthly series for all four measures, 1959 to the latest month, computed from the current BEA underlying PCE detail.</p>

```js
const horizon = view(horizonInput());
```

```js
const sh = series.filter((d) => d.horizon === horizon);
const months = [...new Set(sh.map((d) => +d.date))].sort((a, b) => a - b).slice(-12);
const cell = (t, m) => sh.find((d) => +d.date === t && d.measure === m)?.value;
```

```js
// links built in JS: Framework resolves literal href attributes at build time
display(html`<p><a href=${files[horizon].href} download=${`robust_inflation_${horizon}.csv`}><strong>Download CSV — ${changeLabel(horizon)}</strong></a>
  &nbsp;·&nbsp; <span class="muted">other horizons:</span>
  ${Object.keys(files).filter((h) => h !== horizon).map((h, i) => html`${i ? " · " : ""}<a href=${files[h].href} download=${`robust_inflation_${h}.csv`}>${changeLabel(h)}</a>`)}</p>`);
```

<div class="card">
  <h2>Last 12 months — ${changeLabel(horizon)}</h2>
  <table class="preview">
    <thead><tr><th>Month</th>${MEASURES.map((m) => html`<th>${m}</th>`)}</tr></thead>
    <tbody>${months.map((t) => html`<tr><td>${new Date(t).toISOString().slice(0, 7)}</td>${MEASURES.map((m) => html`<td>${cell(t, m)?.toFixed(2) ?? "–"}</td>`)}</tr>`)}</tbody>
  </table>
</div>

## Methods

Headline and core PCE are BEA aggregates. The median and trimmed mean are computed from the roughly 180 detailed PCE categories: each category's price change is weighted by its share of spending, then the weighted middle is taken (median), or the weighted tails are discarded and the rest averaged (trimmed mean). This reproduces the methodology of Ocampo, Schoenle & Smith on the latest data vintage. 1- and 3-month changes are annualized.

<p class="muted">BEA revises history, so figures reflect the current vintage and differ slightly from the frozen published paper. This is a living companion to the paper, not its archival record.</p>

<style>
table.preview { width: 100%; max-width: none; font-size: 14px; font-variant-numeric: tabular-nums; }
table.preview td:nth-child(n+2), table.preview th:nth-child(n+2) { text-align: right; }
</style>
