---
title: What's driving it
---

```js
import * as Plot from "npm:@observablehq/plot";
import {palette, fmt, HORIZONS, horizonText, monthsBefore} from "./components/theme.js";
import {segmented} from "./components/controls.js";
import {timeChart, legend, contributionTable, tableView, plotStyle} from "./components/charts.js";
const drivers = FileAttachment("data/drivers.json").json();
const pctFiles = {"12m": FileAttachment("data/percentiles/12m.csv"), "3m": FileAttachment("data/percentiles/3m.csv"), "1m": FileAttachment("data/percentiles/1m.csv")};
```

<p class="eyebrow">Drivers</p>

# What's driving inflation this month?

<p class="lede">Every month, roughly 180 categories of consumer spending each have their own price change. Headline inflation averages all of them. The trimmed mean sets aside the most extreme changes at both ends and averages the rest, so one volatile category, gasoline for example, cannot swing the measure.</p>

```js
const horizonInput = segmented(HORIZONS, {label: "Change over", value: "12m", key: "rrm-horizon"});
display(html`<div class="controls">${horizonInput}</div>`);
const horizon = Generators.input(horizonInput);
```

```js
const c = palette(dark);
const d = drivers.find((r) => r.horizon === horizon);
const month = new Date(d.month);
const M = d.markers;
const markers = [
  {label: "Headline PCE", value: M["Headline PCE"], color: c.series["Headline PCE"]},
  {label: "Median PCE", value: M["Median PCE"], color: c.series["Median PCE"]},
  {label: "Trimmed-mean PCE", value: M["Trimmed-mean PCE"], color: c.series["Trimmed-mean PCE"]}
];
const binLabel = (b) => `${(b.x - 0.5).toFixed(0)}% to ${(b.x + 0.5).toFixed(0)}%`;
```

<div class="card">
  <h3>Price changes across categories, ${fmt.month(month)}</h3>
  <p class="sub">Share of consumer spending in each 1-point range of price change (${horizonText[horizon]}). Blue bars are what the trimmed mean averages; grey bars are the extremes it sets aside: the lowest-changing 24% and highest-changing 31% of spending. A few categories lie beyond the range shown. Lines mark where each measure lands.</p>
  ${legend([
    {label: "Kept by the trimmed mean", kind: "area", color: c.series["Trimmed-mean PCE"]},
    {label: "Set aside", kind: "area", color: c.muted},
    ...markers.map((m) => ({label: `${m.label} ${fmt.pct(m.value)}`, kind: "line", color: m.color}))
  ])}
  ${resize((width) => Plot.plot({
    width, height: 330, marginLeft: 44, marginBottom: 34, marginTop: 10,
    style: plotStyle(c),
    x: {domain: [-12, 18], label: `${horizonText[horizon]} by category (%)`, labelAnchor: "center", labelArrow: "none", tickFormat: (v) => `${v}%`},
    y: {grid: true, label: null, tickFormat: (v) => `${Math.round(100 * v)}%`},
    marks: [
      Plot.rectY(d.bins, {x1: (b) => b.x - 0.5, x2: (b) => b.x + 0.5, y: "w", insetLeft: 1, insetRight: 1, clip: true,
        fill: (b) => (b.kept ? c.series["Trimmed-mean PCE"] : c.muted), fillOpacity: 0.35}),   // washes, so the marker lines stay visible
      Plot.ruleY([0], {stroke: c.axis}),
      ...markers.filter((m) => m.value != null).map((m) => Plot.ruleX([m.value], {stroke: m.color, strokeWidth: 2, clip: true})),
      Plot.tip(d.bins, Plot.pointerX({x: "x", y: "w", title: (b) => `${(100 * b.w).toFixed(1)}% of spending\n${binLabel(b)}, ${b.kept ? "kept" : "set aside"}`,
        fill: c.surface, stroke: c.axis, textPadding: 8}))
    ]
  }))}
  ${tableView([
    {label: "Price change", value: binLabel},
    {label: "Share of spending", num: true, value: (b) => `${(100 * b.w).toFixed(1)}%`},
    {label: "Trimmed mean", value: (b) => (b.kept ? "kept" : "set aside")}
  ], d.bins)}
</div>

## What the trimmed mean sets aside

<p class="muted">The extreme categories this month, ranked by their approximate pull on headline inflation (share of spending × price change). ${d.n_high} categories are set aside at the top and ${d.n_low} at the bottom, out of ${d.n}.</p>

<div class="card"><h3>Set aside at the top: the largest price increases</h3>${contributionTable(d.high_tail)}</div>

<div class="card"><h3>Set aside at the bottom: the smallest increases and the declines</h3>${contributionTable(d.low_tail)}</div>

## The spread of price changes over time

```js
const spanInput = segmented(new Map([["10 years", "10"], ["Since 1990", "1990"], ["Since 1960", "0"]]), {label: "Show", value: "10"});
display(html`<div class="controls">${spanInput}</div>`);
const span = Generators.input(spanInput);
```

```js
const pcts = pctFiles[horizon].csv({typed: true});
```

```js
const pEnd = pcts.at(-1).date;
const pStart = span === "10" ? monthsBefore(pEnd, 120) : span === "1990" ? new Date(Date.UTC(1990, 0, 1)) : pcts[0].date;
const pw = pcts.filter((r) => r.date >= pStart);
const col = (q) => pw.map((r) => ({date: r.date, value: r[q]}));
```

<div class="card">
  <h3>Percentiles of category price changes</h3>
  <p class="sub">${horizonText[horizon][0].toUpperCase() + horizonText[horizon].slice(1)}, weighted by spending (the paper's Figure 2). The shaded band, from the 24th to the 69th percentile, is the slice the trimmed mean averages; the 50th percentile is the median.</p>
  ${resize((width) => timeChart({c, width, height: 360,
    band: {label: "24th–69th percentile", color: c.series["Trimmed-mean PCE"], rows: pw.map((r) => ({date: r.date, lo: r.p24, hi: r.p69})), opacity: 0.14},
    lines: [
      {label: "90th percentile", color: c.muted, rows: col("p90"), strokeWidth: 1.5},
      {label: "50th percentile", color: c.series["Median PCE"], rows: col("p50")},
      {label: "10th percentile", color: c.muted, rows: col("p10"), strokeWidth: 1.5}
    ],
    keys: [
      {label: "24th–69th percentile (kept by the trimmed mean)", kind: "area", color: c.series["Trimmed-mean PCE"]},
      {label: "50th percentile (median)", kind: "line", color: c.series["Median PCE"]},
      {label: "10th and 90th percentiles", kind: "line", color: c.muted}
    ]}))}
  ${tableView([
    {label: "Month", value: (r) => fmt.ym(r.date)},
    ...["p10", "p24", "p50", "p69", "p90"].map((q) => ({label: `${q.slice(1)}th`, num: true, value: (r) => r[q].toFixed(2)}))
  ], [...pw].reverse())}
</div>
