---
title: Measure disagreement
---

```js
import {colorOf, horizonInput, changeLabel, monthLabel} from "./components/style.js";
const dis = FileAttachment("data/disagreement.csv").csv({typed: true});
const summary = FileAttachment("data/disagreement-summary.json").json();
```

# How much do the measures disagree?

<p class="muted">The shaded band is the range spanned by core PCE, the median and the trimmed mean each month — a gauge of how much the choice of measure matters. It widens when inflation is turning.</p>

```js
const horizon = view(horizonInput());
```

```js
const s = summary.find((d) => d.horizon === horizon);
const d = dis.filter((r) => r.horizon === horizon);
const spread = (v) => (v == null ? "–" : v.toFixed(1));
```

<div class="grid grid-cols-4">
  <div class="card"><h2>Latest</h2><span class="big">${spread(s.latest)}</span><p class="muted">pp spread, ${monthLabel(new Date(s.latest_date))}</p></div>
  <div class="card"><h2>Average</h2><span class="big">${spread(s.average)}</span><p class="muted">pp spread, all months</p></div>
  <div class="card"><h2>Low inflation (&lt;2.5%)</h2><span class="big">${spread(s.low)}</span><p class="muted">pp spread</p></div>
  <div class="card"><h2>High inflation (≥5%)</h2><span class="big">${spread(s.high)}</span><p class="muted">pp spread</p></div>
</div>

```js
const years = view(Inputs.radio(new Map([["Last 5 years", 5], ["Last 10 years", 10], ["Full history", 0]]), {label: "Time window", value: 10}));
```

```js
const end = d3.max(d, (r) => r.date);
const w = d.filter((r) => !years || r.date >= d3.utcYear.offset(end, -years));
```

<div class="card">${resize((width) => Plot.plot({
  width, height: 420, marginLeft: 45,
  y: {grid: true, label: changeLabel(horizon) + " (%)", tickFormat: (v) => `${v}%`},
  x: {label: null},
  color: {legend: true, domain: ["Range of robust measures", "Headline PCE"], range: ["#bdbdbd", colorOf("Headline PCE")]},
  marks: [
    Plot.areaY(w, {x: "date", y1: "lo", y2: "hi", fill: "#bdbdbd", fillOpacity: 0.7}),
    Plot.ruleY([2], {stroke: "#bbb", strokeDasharray: "4,3"}),
    Plot.lineY(w, {x: "date", y: "headline", stroke: colorOf("Headline PCE"), strokeWidth: 1.6}),
    Plot.ruleX(w, Plot.pointerX({x: "date", stroke: "#999", strokeOpacity: 0.7})),
    Plot.tip(w, Plot.pointerX({x: "date", y: "hi", title: (r) => `${monthLabel(r.date)}\nRobust measures: ${r.lo.toFixed(2)}–${r.hi.toFixed(2)}% (spread ${r.diff.toFixed(2)} pp)\nHeadline PCE: ${r.headline?.toFixed(2)}%`}))
  ]
}))}</div>

<p class="muted">Band = max minus min of core PCE, median PCE and the trimmed mean. Line = headline PCE. Dashed line: 2% target. 1- and 3-month changes are annualized.</p>
