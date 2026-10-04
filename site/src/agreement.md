---
title: Do the measures agree?
---

```js
import {palette, fmt, HORIZONS, horizonText, monthsBefore} from "./components/theme.js";
import {segmented} from "./components/controls.js";
import {timeChart, statTile, tableView} from "./components/charts.js";
const files = {"12m": FileAttachment("data/agreement/12m.csv"), "3m": FileAttachment("data/agreement/3m.csv"), "1m": FileAttachment("data/agreement/1m.csv")};
const summary = FileAttachment("data/agreement-summary.json").json();
```

<p class="eyebrow">Agreement</p>

# Do the measures of underlying inflation agree?

<p class="lede">Core, median and trimmed-mean inflation are three answers to the same question. When they tell the same story, any of them will do. When they diverge, the choice of measure matters, and this tends to happen exactly when inflation is turning.</p>

```js
const horizonInput = segmented(HORIZONS, {label: "Change over", value: "12m", key: "rrm-horizon"});
const spanInput = segmented(new Map([["5 years", 5], ["10 years", 10], ["Since 1960", 0]]), {label: "Show", value: 10});
display(html`<div class="controls">${horizonInput}${spanInput}</div>`);
const horizon = Generators.input(horizonInput);
const years = Generators.input(spanInput);
```

```js
const rows = files[horizon].csv({typed: true});
```

```js
const c = palette(dark);
const s = summary.find((d) => d.horizon === horizon);
const last = rows.at(-1).date;
const w = rows.filter((d) => d.date >= (years ? monthsBefore(last, 12 * years) : new Date(Date.UTC(1960, 0, 1))));
const pp = (v) => `${v.toFixed(1)} pp`;
```

<div class="tiles">
  ${statTile({label: "Spread now", value: pp(s.latest), delta: `Highest minus lowest measure, ${fmt.month(new Date(s.latest_date))}`})}
  ${statTile({label: "Average spread", value: pp(s.average), delta: "All months since 1960"})}
  ${statTile({label: "When headline is below 2.5%", value: pp(s.low), delta: "Average spread"})}
  ${statTile({label: "When headline is 5% or more", value: pp(s.high), delta: "Average spread"})}
</div>

<div class="card">
  <h3>Range spanned by core, median and trimmed-mean inflation</h3>
  <p class="sub">${horizonText[horizon][0].toUpperCase() + horizonText[horizon].slice(1)}. The shaded band runs from the lowest to the highest of the three each month; headline is shown for context.</p>
  ${resize((width) => timeChart({c, width, height: 360,
    band: {label: "Range of core, median and trimmed mean", color: c.band, rows: w, opacity: 0.17},
    lines: [{label: "Headline PCE", color: c.series["Headline PCE"], rows: w.map((d) => ({date: d.date, value: d.headline}))}]}))}
</div>

<div class="card">
  <h3>How far apart they are</h3>
  <p class="sub">Highest minus lowest of the three, in percentage points.</p>
  ${resize((width) => timeChart({c, width, height: 220, target: null, unit: " pp",
    lines: [{label: "Spread", color: c.ink2, rows: w.map((d) => ({date: d.date, value: d.spread}))}]}))}
  ${tableView([
    {label: "Month", value: (d) => fmt.ym(d.date)},
    {label: "Lowest", num: true, value: (d) => d.lo.toFixed(2)},
    {label: "Highest", num: true, value: (d) => d.hi.toFixed(2)},
    {label: "Spread", num: true, value: (d) => d.spread.toFixed(2)},
    {label: "Headline", num: true, value: (d) => d.headline?.toFixed(2) ?? "–"}
  ], [...w].reverse())}
</div>

<p class="footnote">The paper's Appendix Figure B.1 shows this range for 1960–2024. The series start in early 1960 (the median and trimmed mean one month after core), so the very first month shows no spread.</p>
