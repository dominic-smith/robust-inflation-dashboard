---
title: Latest reading
---

```js
import {MEASURES, COLORS, colorOf, HORIZONS, horizonLabel, pct, monthLabel} from "./components/style.js";
const series = FileAttachment("data/series.csv").csv({typed: true});
```

# What is inflation now?

```js
const horizon = view(Inputs.radio(HORIZONS, {label: "Horizon", value: "12m"}));
```

```js
const sh = series.filter((d) => d.horizon === horizon);
const maxDate = d3.max(sh, (d) => d.date);
const latest = new Map(sh.filter((d) => +d.date === +maxDate).map((d) => [d.measure, d.value]));
```

<p class="muted">Consumer price inflation, four ways. Data through ${monthLabel(maxDate)}. 1-month and 3-month changes are annualized.</p>

<div class="grid grid-cols-4">
  ${MEASURES.map((m) => html`<div class="card">
    <h2>${m}</h2>
    <span class="big" style="color: ${colorOf(m)}">${pct(latest.get(m))}</span>
  </div>`)}
</div>

```js
const years = view(Inputs.radio(new Map([["Last 3 years", 3], ["Last 5 years", 5], ["Last 10 years", 10], ["Full history", 0]]), {label: "Time window", value: 5}));
const shown = view(Inputs.checkbox(MEASURES, {label: "Measures", value: MEASURES}));
```

```js
const cutoff = years ? d3.utcYear.offset(maxDate, -years) : d3.min(sh, (d) => d.date);
const plotData = sh.filter((d) => d.date >= cutoff && shown.includes(d.measure));
// one tooltip row per month, listing every visible measure
const byDate = d3.groups(plotData, (d) => +d.date).map(([t, rows]) => ({
  date: new Date(t),
  top: d3.max(rows, (r) => r.value),
  text: [monthLabel(new Date(t)), ...MEASURES.filter((m) => rows.some((r) => r.measure === m))
    .map((m) => `${m}: ${rows.find((r) => r.measure === m).value.toFixed(2)}%`)].join("\n")
}));
```

<div class="card">${resize((width) => Plot.plot({
  width,
  height: 420,
  marginLeft: 45,
  y: {grid: true, label: horizonLabel(horizon) + " (%)", tickFormat: (d) => `${d}%`},
  x: {label: null},
  color: {domain: MEASURES, range: COLORS, legend: true},
  marks: [
    Plot.ruleY([2], {stroke: "#bbb", strokeDasharray: "4,3"}),
    Plot.lineY(plotData, {x: "date", y: "value", stroke: "measure", strokeWidth: 1.8}),
    Plot.ruleX(byDate, Plot.pointerX({x: "date", stroke: "#999", strokeOpacity: 0.7})),
    Plot.tip(byDate, Plot.pointerX({x: "date", y: "top", title: "text"}))
  ]
}))}</div>

<p class="muted">Dashed line: 2% target. Headline and core PCE are BEA aggregates; the median and trimmed mean are computed from the detailed PCE categories using the paper's methodology.</p>
