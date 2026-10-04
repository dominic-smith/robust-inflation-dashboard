---
title: Underlying inflation range
---

```js
import {palette, fmt, TARGETS, TARGET_NOTE, SAMPLES, monthsBefore} from "./components/theme.js";
import {segmented} from "./components/controls.js";
import {timeChart, statTile, tableView, deltaText} from "./components/charts.js";
// one small file per trend measure x sample; only the selected one is fetched
const bands = {
  "c_0_37-long": FileAttachment("data/band/c_0_37-long.csv"), "c_0_37-80s": FileAttachment("data/band/c_0_37-80s.csv"), "c_0_37-00s": FileAttachment("data/band/c_0_37-00s.csv"),
  "f_12_24-long": FileAttachment("data/band/f_12_24-long.csv"), "f_12_24-80s": FileAttachment("data/band/f_12_24-80s.csv"), "f_12_24-00s": FileAttachment("data/band/f_12_24-00s.csv"),
  "f_0_24-long": FileAttachment("data/band/f_0_24-long.csv"), "f_0_24-80s": FileAttachment("data/band/f_0_24-80s.csv"), "f_0_24-00s": FileAttachment("data/band/f_0_24-00s.csv"),
  "b_2_39-long": FileAttachment("data/band/b_2_39-long.csv"), "b_2_39-80s": FileAttachment("data/band/b_2_39-80s.csv"), "b_2_39-00s": FileAttachment("data/band/b_2_39-00s.csv")
};
const meta = FileAttachment("data/band-meta.json").json();
const series = FileAttachment("data/series/12m.csv").csv({typed: true});
```

<p class="eyebrow">Underlying inflation</p>

# What range of underlying inflation do the best trims support?

<p class="lede">A trimmed mean drops a share of the most extreme price changes each month. The paper evaluates all 2,601 combinations of how much to trim from each end, and finds that many track trend inflation about equally well: their errors cannot be statistically distinguished from the best trim's (Diebold–Mariano test, 5% level). The band below is the range of 12-month inflation those trims produce each month. It is the paper's Figure 1, recomputed on the latest data.</p>

```js
const targetInput = segmented(TARGETS, {label: "Trend measure", value: "c_0_37"});
const sampleInput = segmented(SAMPLES, {label: "Trims chosen on", value: "long"});
const spanInput = segmented(new Map([["Since 2020", "2020"], ["10 years", "10"], ["All", "0"]]), {label: "Show", value: "2020"});
display(html`<div class="controls">${targetInput}${sampleInput}${spanInput}</div>`);
const target = Generators.input(targetInput);
const sample = Generators.input(sampleInput);
const span = Generators.input(spanInput);
```

```js
const band = bands[`${target}-${sample}`].csv({typed: true});
```

```js
const c = palette(dark);
const last = band.at(-1);
const then = monthsBefore(last.date, 3);
const bThen = band.find((d) => +d.date === +then);
const n = meta.find((m) => m.target === target && m.sample === sample).n_trims;
const start = span === "2020" ? new Date(Date.UTC(2020, 0, 1)) : span === "10" ? monthsBefore(last.date, 120) : band[0].date;
const bw = band.filter((d) => d.date >= start);
const pick = (m) => series.filter((d) => d.measure === m && d.date >= start && d.date <= last.date).map(({date, value}) => ({date, value}));
const index = new Map(series.map((d) => [`${d.measure}|${+d.date}`, d.value]));  // O(1) lookups for tiles and tables
const at = (m, date) => index.get(`${m}|${+date}`);
```

<div class="tiles">
  ${statTile({label: "Range of the best trims", value: `${last.lo.toFixed(1)}–${last.hi.toFixed(1)}%`, delta: `12-month change, ${fmt.month(last.date)}`})}
  ${statTile({label: "Best-trims average", keyClass: "k-band", value: fmt.pct(last.mean), delta: deltaText(last.mean, bThen?.mean, fmt.monthShort(then))})}
  ${statTile({label: "Trimmed-mean PCE", keyClass: "k-tm", value: fmt.pct(at("Trimmed-mean PCE", last.date)), delta: deltaText(at("Trimmed-mean PCE", last.date), at("Trimmed-mean PCE", then), fmt.monthShort(then))})}
  ${statTile({label: "Trims in the set", value: String(n), delta: "of 2,601 candidate trims"})}
</div>

<div class="card">
  <h3>Range of the best trims, with the main measures</h3>
  <p class="sub">12-month change. Trims chosen to track ${TARGET_NOTE[target]}, evaluated over ${[...SAMPLES].find(([, v]) => v === sample)[0]}.</p>
  ${resize((width) => timeChart({c, width, height: 380,
    band: {label: "Range of best trims", color: c.band, rows: bw, opacity: 0.17},
    lines: [
      {label: "Best-trims average", color: c.ink, rows: bw.map((d) => ({date: d.date, value: d.mean}))},
      {label: "Trimmed-mean PCE", color: c.series["Trimmed-mean PCE"], rows: pick("Trimmed-mean PCE")},
      {label: "Median PCE", color: c.series["Median PCE"], rows: pick("Median PCE")},
      {label: "Headline PCE", color: c.series["Headline PCE"], rows: pick("Headline PCE")}
    ]}))}
  ${tableView([
    {label: "Month", value: (d) => fmt.ym(d.date)},
    {label: "Low", num: true, value: (d) => d.lo.toFixed(2)},
    {label: "High", num: true, value: (d) => d.hi.toFixed(2)},
    {label: "Average", num: true, value: (d) => d.mean.toFixed(2)},
    {label: "Trimmed mean", num: true, value: (d) => at("Trimmed-mean PCE", d.date)?.toFixed(2) ?? "–"},
    {label: "Median", num: true, value: (d) => at("Median PCE", d.date)?.toFixed(2) ?? "–"},
    {label: "Headline", num: true, value: (d) => at("Headline PCE", d.date)?.toFixed(2) ?? "–"}
  ], [...bw].reverse())}
</div>

## Reading the range

- **A narrow band** means the choice of trim barely matters: the data pin down underlying inflation tightly. **A wide band** is a warning that any single trimmed mean is less precise than it looks.
- **The trend measure** is the yardstick the trims were scored against. *Current trend* is a centered average of headline inflation; *future* and *forward trend* look ahead, so the trims chosen for them are the ones that best predict where inflation is going.
- **The sample** is the period over which trims were scored. Sets chosen on 1970–1989 reflect a high-inflation era; 2000–2024 reflects the low-inflation period.
- Which trims belong to each set is fixed by the paper's evaluation; each month every trim in the set is recomputed on the latest BEA data. The official trimmed mean (24% off the bottom, 31% off the top) is inside the set for the future trend but just outside it for the current trend.
