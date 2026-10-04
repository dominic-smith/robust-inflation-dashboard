---
title: The four measures
---

```js
import {palette, fmt, MEASURES, KEY, HORIZONS, horizonText, monthsBefore} from "./components/theme.js";
import {segmented, checkboxes} from "./components/controls.js";
import {timeChart, statTile, tableView, deltaText, sparkline} from "./components/charts.js";
const files = {"12m": FileAttachment("data/series/12m.csv"), "3m": FileAttachment("data/series/3m.csv"), "1m": FileAttachment("data/series/1m.csv")};
```

<p class="eyebrow">Measures</p>

# Headline, core, median and trimmed-mean inflation

<p class="lede">Four ways to measure consumer price inflation from the same PCE data. Headline counts every category; core drops food and energy; the median and trimmed mean drop the most extreme price changes, whatever category they come from, so a single volatile category cannot swing them.</p>

```js
const horizonInput = segmented(HORIZONS, {label: "Change over", value: "12m", key: "rrm-horizon"});
const spanInput = segmented(new Map([["3 years", 3], ["5 years", 5], ["10 years", 10], ["Since 1960", 0]]), {label: "Show", value: 5});
const pickInput = checkboxes(MEASURES, {label: "Measures", keyClass: (m) => `k-${KEY[m]}`});
display(html`<div class="controls">${horizonInput}${spanInput}${pickInput}</div>`);
const horizon = Generators.input(horizonInput);
const years = Generators.input(spanInput);
const shown = Generators.input(pickInput);
```

```js
const series = files[horizon].csv({typed: true});
```

```js
const c = palette(dark);
const last = series.reduce((m, d) => (d.date > m ? d.date : m), series[0].date);
const then = monthsBefore(last, 3);
const index = new Map(series.map((d) => [`${d.measure}|${+d.date}`, d.value]));  // O(1) lookups for tiles and tables
const at = (m, date) => index.get(`${m}|${+date}`);
const start = years ? monthsBefore(last, 12 * years) : new Date(Date.UTC(1960, 0, 1));
const rows = (m) => series.filter((d) => d.measure === m && d.date >= start).map(({date, value}) => ({date, value}));
const recent = (m) => series.filter((d) => d.measure === m && d.date > monthsBefore(last, 24)).map((d) => d.value);
const months = [...new Set(series.filter((d) => d.date >= start).map((d) => +d.date))].sort((a, b) => b - a).map((t) => new Date(t));
```

<div class="tiles">
  ${MEASURES.map((m) => statTile({label: m, keyClass: `k-${KEY[m]}`, value: fmt.pct(at(m, last)),
    delta: deltaText(at(m, last), at(m, then), fmt.monthShort(then)), spark: sparkline(recent(m), `k-${KEY[m]}`)}))}
</div>

<div class="card">
  <h3>${horizonText[horizon][0].toUpperCase() + horizonText[horizon].slice(1)}, through ${fmt.month(last)}</h3>
  <p class="sub">${horizon === "12m" ? "Change from the same month a year earlier." : `Change over the last ${horizon === "1m" ? "month" : "three months"}, expressed as an annual rate. Shorter horizons react sooner but are noisier.`}</p>
  ${shown.length ? resize((width) => timeChart({c, width, height: 380,
    lines: MEASURES.filter((m) => shown.includes(m)).map((m) => ({label: m, color: c.series[m], rows: rows(m)}))})) : html`<p class="muted">Choose at least one measure.</p>`}
  ${tableView([{label: "Month", value: (d) => fmt.ym(d)}, ...MEASURES.map((m) => ({label: m, num: true, value: (d) => at(m, d)?.toFixed(2) ?? "–"}))], months)}
</div>

<p class="footnote">Headline and core PCE are BEA's published price indexes. The median and trimmed mean are computed by the authors from BEA's detailed category data, following the Cleveland Fed's and Dallas Fed's definitions, and differ slightly from the official series. Each is dated to the month of the price change it measures.</p>
