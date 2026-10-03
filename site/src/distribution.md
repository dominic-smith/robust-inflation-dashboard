---
title: Distribution
---

```js
import {colorOf, horizonInput, changeLabel, monthLabel} from "./components/style.js";
const dist = FileAttachment("data/dist.json").json();
const series = FileAttachment("data/series.csv").csv({typed: true});
const pcts = FileAttachment("data/percentiles.csv").csv({typed: true});
```

# What trimming removes

```js
const horizon = view(horizonInput());
```

```js
const d = dist.find((r) => r.horizon === horizon);
const month = new Date(d.month);
const sh = series.filter((r) => r.horizon === horizon);
const last = d3.max(sh, (r) => r.date);
const at = (m) => sh.find((r) => r.measure === m && +r.date === +last)?.value;
const markers = [
  {name: "Headline (mean)", value: at("Headline PCE"), color: "#111111"},
  {name: "Median", value: at("Cleveland median"), color: colorOf("Cleveland median")},
  {name: "Trimmed mean", value: at("Dallas trimmed mean"), color: colorOf("Dallas trimmed mean")}
];
const tailTable = (rows) => html`<table class="tail">
  <thead><tr><th>Category</th><th>Change</th><th>Weight</th></tr></thead>
  <tbody>${rows.map((r) => html`<tr><td>${r.category}</td><td>${r.change >= 0 ? "+" : ""}${r.change.toFixed(1)}%</td><td>${r.weight.toFixed(1)}%</td></tr>`)}</tbody></table>`;
```

<p class="muted">${monthLabel(month)}. Each detailed PCE category's price change (${changeLabel(horizon)}), weighted by its share of spending. The trimmed mean discards the weighted tails (grey) and averages the rest; the median is the middle. Headline keeps everything.</p>

<div class="card">${resize((width) => Plot.plot({
  width, height: 400, marginLeft: 50,
  x: {domain: [-12, 18], label: `${changeLabel(horizon)} by category (%)`},
  y: {grid: true, label: "Share of spending"},
  color: {legend: true, domain: ["Kept (averaged)", "Trimmed away", ...markers.map((m) => m.name)],
          range: ["#4C78A8", "#C9CDD2", ...markers.map((m) => m.color)]},
  marks: [
    Plot.rectY(d.bins, {x1: (b) => b.x - 0.5, x2: (b) => b.x + 0.5, y: "w", fill: "status", stroke: "white", clip: true}),
    Plot.ruleX(markers.filter((m) => m.value != null), {x: "value", stroke: "color", strokeWidth: 2, clip: true}),
    Plot.tip(d.bins, Plot.pointerX({x: "x", y: "w", title: (b) => `${(b.x - 0.5).toFixed(0)}% to ${(b.x + 0.5).toFixed(0)}%\n${(100 * b.w).toFixed(1)}% of spending — ${b.status.toLowerCase()}`}))
  ]
}))}</div>

## What the trimmed mean discards

<p class="muted">The categories in the trimmed tails this month, largest weight first (${d.n_low} categories in the low tail, ${d.n_high} in the high tail).</p>

<div class="grid grid-cols-2">
  <div class="card"><h2>Cheapest (low tail)</h2>${tailTable(d.low_tail)}</div>
  <div class="card"><h2>Most expensive (high tail)</h2>${tailTable(d.high_tail)}</div>
</div>

## The spread of price changes over time

<p class="muted">Percentiles of category price changes each month, weighted by spending (the paper's Figure 2). The shaded 24th–69th band is the slice the trimmed mean averages; the 50th percentile is the median.</p>

```js
const start = view(Inputs.radio(new Map([["Last 10 years", "10"], ["Since 1990", "1990"], ["Full history (1960–)", "0"]]), {label: "Time window", value: "10"}));
```

```js
const ph = pcts.filter((r) => r.horizon === horizon);
const pEnd = d3.max(ph, (r) => r.date);
const pw = ph.filter((r) => start === "0" || r.date >= (start === "1990" ? new Date(Date.UTC(1990, 0, 1)) : d3.utcYear.offset(pEnd, -10)));
const pl = ["p10", "p24", "p50", "p69", "p90"].flatMap((q) => pw.map((r) => ({date: r.date, q, value: r[q],
  grp: q === "p50" ? "50th (median)" : q === "p24" || q === "p69" ? "24th & 69th (trimmed-mean cut points)" : "10th & 90th"})));
```

<div class="card">${resize((width) => Plot.plot({
  width, height: 400, marginLeft: 45,
  y: {grid: true, label: changeLabel(horizon) + " (%)", tickFormat: (v) => `${v}%`},
  x: {label: null},
  color: {legend: true, domain: ["10th & 90th", "24th & 69th (trimmed-mean cut points)", "50th (median)"],
          range: ["#8DA0B3", colorOf("Dallas trimmed mean"), colorOf("Cleveland median")]},
  marks: [
    Plot.areaY(pw, {x: "date", y1: "p24", y2: "p69", fill: colorOf("Dallas trimmed mean"), fillOpacity: 0.12}),
    Plot.ruleY([2], {stroke: "#bbb", strokeDasharray: "4,3"}),
    Plot.lineY(pl, {x: "date", y: "value", z: "q", stroke: "grp", strokeWidth: 1.1}),
    Plot.ruleX(pw, Plot.pointerX({x: "date", stroke: "#999", strokeOpacity: 0.7})),
    Plot.tip(pw, Plot.pointerX({x: "date", y: "p90", title: (r) => `${monthLabel(r.date)}\n90th: ${r.p90.toFixed(1)}%\n69th: ${r.p69.toFixed(1)}%\n50th: ${r.p50.toFixed(1)}%\n24th: ${r.p24.toFixed(1)}%\n10th: ${r.p10.toFixed(1)}%`}))
  ]
}))}</div>

<style>
table.tail { width: 100%; max-width: none; font-size: 13px; }
table.tail td:nth-child(n+2), table.tail th:nth-child(n+2) { text-align: right; white-space: nowrap; }
</style>
