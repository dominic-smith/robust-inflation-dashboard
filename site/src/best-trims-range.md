---
title: Best-trims range
---

```js
import {MEASURES, colorOf, TARGETS, SAMPLES, pct, monthLabel} from "./components/style.js";
const band = FileAttachment("data/band.csv").csv({typed: true});
const series = FileAttachment("data/series.csv").csv({typed: true});
```

# What range of trend inflation do the best trims support?

<p class="muted">Many trimmed means track trend inflation about equally well: their errors are statistically indistinguishable from the single best trim (Diebold–Mariano test, 5% level). The shaded band shows the 12-month inflation rates that whole set of near-optimal trims produces each month — the paper's Figure 1, updated monthly.</p>

```js
const target = view(Inputs.radio(TARGETS, {label: "Trend measure the trims track", value: "c_0_37"}));
const sample = view(Inputs.radio(SAMPLES, {label: "Sample used to choose them", value: "long"}));
const windowStart = view(Inputs.radio(new Map([["2020 onward (as in Figure 1)", "2020"], ["Last 10 years", "10"], ["Full history", "0"]]), {label: "Time window", value: "2020"}));
```

```js
const b = band.filter((d) => d.target === target && d.sample === sample);
const last = b.at(-1);
const lines = series.filter((d) => d.horizon === "12m" && ["Headline PCE", "Cleveland median", "Dallas trimmed mean"].includes(d.measure));
const tmLast = lines.find((d) => d.measure === "Dallas trimmed mean" && +d.date === +last.date);
const start = windowStart === "2020" ? new Date(Date.UTC(2020, 0, 1))
  : windowStart === "10" ? d3.utcYear.offset(last.date, -10) : b[0].date;
const bw = b.filter((d) => d.date >= start);
const lw = lines.filter((d) => d.date >= start);
// one tooltip row per month: band, set mean, and the three measures
const lineAt = d3.group(lw, (d) => +d.date);
const tipRows = bw.map((d) => {
  const ls = lineAt.get(+d.date) ?? [];
  return {date: d.date, top: d3.max([d.hi, ...ls.map((r) => r.value)]),
    text: [monthLabel(d.date), `Best-trims range: ${d.lo.toFixed(2)}–${d.hi.toFixed(2)}%`, `Set mean: ${d.mean.toFixed(2)}%`,
           ...ls.map((r) => `${r.measure}: ${r.value.toFixed(2)}%`)].join("\n")};
});
```

<div class="grid grid-cols-4">
  <div class="card"><h2>Best-trims range</h2><span class="big">${last.lo.toFixed(1)}–${last.hi.toFixed(1)}%</span><p class="muted">${monthLabel(last.date)}</p></div>
  <div class="card"><h2>Set mean</h2><span class="big">${pct(last.mean)}</span><p class="muted">average of the trims</p></div>
  <div class="card"><h2>Trimmed mean (24/69)</h2><span class="big" style="color: ${colorOf("Dallas trimmed mean")}">${pct(tmLast?.value)}</span><p class="muted">${monthLabel(last.date)}</p></div>
  <div class="card"><h2>Trims in the set</h2><span class="big">${last.n_trims}</span><p class="muted">of 2,601 candidates</p></div>
</div>

<div class="card">${resize((width) => Plot.plot({
  width,
  height: 440,
  marginLeft: 45,
  y: {grid: true, label: "12-month change (%)", tickFormat: (d) => `${d}%`},
  x: {label: null},
  color: {legend: true, domain: ["Range across best trims", "Set mean", "Headline PCE", "Cleveland median", "Dallas trimmed mean"],
          range: ["#c4c4c4", "#333333", colorOf("Headline PCE"), colorOf("Cleveland median"), colorOf("Dallas trimmed mean")]},
  marks: [
    Plot.areaY(bw, {x: "date", y1: "lo", y2: "hi", fill: "#c4c4c4", fillOpacity: 0.75}),
    Plot.ruleY([2], {stroke: "#bbb", strokeDasharray: "4,3"}),
    Plot.lineY(bw, {x: "date", y: "mean", stroke: "#333333", strokeWidth: 1.3}),
    Plot.lineY(lw, {x: "date", y: "value", stroke: "measure", strokeWidth: 1.8}),
    Plot.ruleX(tipRows, Plot.pointerX({x: "date", stroke: "#999", strokeOpacity: 0.7})),
    Plot.tip(tipRows, Plot.pointerX({x: "date", y: "top", title: "text"}))
  ]
}))}</div>

<p class="muted">Which trims are statistically equivalent is fixed from the paper's evaluation; each trim is recomputed on every month's data. Band and lines are 12-month changes. Dashed line: 2% target.</p>
