---
title: Why trimmed means are robust
---

```js
import * as Plot from "npm:@observablehq/plot";
import {palette, TARGETS, TARGET_NOTE, SAMPLES} from "./components/theme.js";
import {segmented} from "./components/controls.js";
import {legend, plotStyle} from "./components/charts.js";
const heatFiles = {4: FileAttachment("data/heat/4.csv"), 5: FileAttachment("data/heat/5.csv")};
const refs = FileAttachment("data/heat-refs.csv").csv({typed: true});
const outline = FileAttachment("data/outline.csv").csv({typed: true});
```

<p class="eyebrow">Robustness</p>

# Which trims best track trend inflation?

<p class="lede">Each square is one trimmed mean, defined by how much it cuts from the bottom (α) and the top (β) of the spending-weighted distribution of price changes. Its colour shows how well it tracks trend inflation: the stronger the blue, the better (see the scale above the chart). The paper's key finding is the broad basin of strong blue. A wide range of trims performs about equally well, so trimmed-mean inflation does not hinge on one exact choice. These results come from the paper's evaluation and are fixed at its data vintage.</p>

```js
const targetInput = segmented(TARGETS, {label: "Trend measure", value: "c_0_37"});
const sampleInput = segmented(SAMPLES, {label: "Sample", value: "long"});
const groupInput = segmented(new Map([["All categories", 4], ["Excluding housing", 5]]), {label: "Categories", value: 4});
const showInput = segmented(new Map([["Accuracy", "rmse"], ["Statistical tie with best", "dm"], ["Average bias", "bias"]]), {label: "Show", value: "rmse"});
display(html`<div class="controls">${targetInput}${sampleInput}${groupInput}${showInput}</div>`);
const target = Generators.input(targetInput);
const sample = Generators.input(sampleInput);
const group = Generators.input(groupInput);
const show = Generators.input(showInput);
```

```js
const heat = heatFiles[group].csv({typed: true});   // the excluding-housing set loads only if chosen
```

```js
const c = palette(dark);
const cells = heat.filter((d) => d.sample === sample && d.target === target);
const ref = refs.filter((d) => d.group === group && d.sample === sample && d.target === target);
const noDM = show === "dm" && group === 5;
const best = show === "dm" ? {lb: ref[0].dm_best_lb, beta: ref[0].dm_best_beta} : {lb: ref[0].best_lb, beta: ref[0].best_beta};
// Strongest step first, with ascending domains (Plot's raster did not honour a descending
// domain with a custom interpolator: low values came out in the weakest colour).
const strong = d3.piecewise(d3.interpolateLab, [...c.ramp].reverse());
const DM_LABELS = {1: "Worse than best (p < 0.01)", 2: "Borderline (0.01–0.05)", 3: "Tied with best (0.05–0.10)", 4: "Tied with best (p ≥ 0.10)"};
const V = {
  rmse: {cells, fill: "rel", color: {type: "linear", domain: [1, 2.5], interpolate: strong, ticks: [1, 1.5, 2, 2.5], tickFormat: (v) => (v === 1 ? "best" : `${v}×`), label: "Error relative to the best trim"},
         say: (d) => `Error ${d.rel.toFixed(2)}× the best trim's`},
  dm:   {cells: cells.filter((d) => d.pcls != null), fill: "pcls",
         color: {type: "ordinal", domain: [1, 2, 3, 4], range: c.dm, tickFormat: (v) => DM_LABELS[v], legend: "swatches"},
         say: (d) => DM_LABELS[d.pcls]},
  bias: {cells: cells.filter((d) => d.bias != null), fill: "bias", color: {type: "linear", domain: [0, 0.5], interpolate: strong, ticks: [0, 0.1, 0.2, 0.3, 0.4, 0.5], label: "Average bias (percentage points)"},
         say: (d) => `Average bias ${d.bias.toFixed(2)} pp`}
}[show];
const segs = show === "bias" && group === 4 ? outline.filter((d) => d.sample === sample && d.target === target) : [];
const marks = [
  {label: "Headline PCE (no trim)", lb: 0, beta: 0, symbol: "circle"},
  {label: "Trimmed-mean PCE (24/31)", lb: 24, beta: 31, symbol: "diamond"},
  {label: "Median PCE", lb: 50, beta: 50, symbol: "square"},
  {label: "Trimmed CPI (8/8)", lb: 8, beta: 8, symbol: "triangle"}
];
```

<div class="robust-grid">
  <div class="card">
    <h3>Every trim, scored against ${TARGET_NOTE[target]}</h3>
    <p class="sub">Lower trim α on the horizontal axis, upper trim β on the vertical. The star is the best trim.</p>
    ${noDM ? html`<p class="muted">The statistical tests were run for all categories only. Choose “All categories”.</p>` : html`
      ${legend([...marks.map((m) => ({label: m.label, kind: m.symbol, color: c.ink})), {label: `Best trim (${best.lb}/${best.beta})`, kind: "star", color: c.star}])}
      ${resize((width) => {
        const w = Math.min(width, 600);
        return Plot.plot({
          width: w, height: w * 0.95, marginLeft: 44, marginBottom: 44, marginTop: 26, marginRight: 8,
          style: plotStyle(c),
          x: {domain: [-0.5, 50.5], label: "Lower trim α (% of spending)", labelAnchor: "center", labelArrow: "none", ticks: [0, 10, 20, 30, 40, 50]},
          y: {domain: [-0.5, 50.5], label: "Upper trim β (%)", labelArrow: "none", ticks: [0, 10, 20, 30, 40, 50]},
          color: {...V.color, legend: true},
          marks: [
            Plot.raster(V.cells, {x: "lb", y: "beta", fill: V.fill, x1: -0.5, x2: 50.5, y1: -0.5, y2: 50.5, width: 51, height: 51, imageRendering: "pixelated"}),
            Plot.link([0], {x1: 0, y1: 0, x2: 50, y2: 50, stroke: c.muted, strokeOpacity: 0.6}),
            Plot.link(segs, {x1: "x1", y1: "y1", x2: "x2", y2: "y2", stroke: c.ink, strokeWidth: 1.5}),
            Plot.dot(marks, {x: "lb", y: "beta", symbol: "symbol", r: 5, fill: c.surface, stroke: c.ink, strokeWidth: 1.4}),
            Plot.dot([best], {x: "lb", y: "beta", symbol: "star", r: 9, fill: c.star, stroke: c.surface, strokeWidth: 1.5}),
            Plot.tip(V.cells, Plot.pointer({x: "lb", y: "beta", title: (d) => `Trim ${d.lb}% from the bottom, ${d.beta}% from the top\n${V.say(d)}`,
              fill: c.surface, stroke: c.axis, textPadding: 8}))
          ]
        });
      })}`}
  </div>
  <div class="card">
    <h3>How the main measures score</h3>
    <p class="sub">Root mean squared error against the trend measure, in percentage points (lower is better).</p>
    <table><tbody>${["Headline PCE", "Core PCE", "Median PCE", "Trimmed mean", "NY Fed UIG", "Best trim"].map((m) => {
      const r = ref.find((x) => x.measure === m);
      return html`<tr><td>${m === "Best trim" ? `Best trim (${ref[0].best_lb}/${ref[0].best_beta})` : m === "Trimmed mean" ? "Trimmed-mean PCE (24/31)" : m === "NY Fed UIG" ? "NY Fed Underlying Inflation Gauge" : m}</td><td class="num">${r ? r.rmse.toFixed(2) : "–"}</td></tr>`;
    })}</tbody></table>
    <p class="footnote">${{
      rmse: "Colour: each trim's error divided by the best trim's. The strongest blue squares are within a few percent of the best.",
      dm: "Colour: a Diebold–Mariano test of each trim's errors against the best trim's. Trims with p ≥ 0.05 are statistically tied with the best, and that set defines the Underlying inflation range page.",
      bias: group === 4 ? "Colour: the square root of each trim's average squared bias against the trend measure; trims with bias of 0.5 pp or more are left blank. The outline encloses trims not statistically worse than the best at the 1% level, as in the paper." : "Colour: the square root of each trim's average squared bias; trims with bias of 0.5 pp or more are left blank. The statistical outline is available for all categories only."
    }[show]}</p>
  </div>
</div>

<style>
.robust-grid { display: grid; grid-template-columns: minmax(0, 1.7fr) minmax(250px, 1fr); gap: 0.8rem; margin: 0.8rem 0; align-items: start; }
@media (max-width: 860px) { .robust-grid { grid-template-columns: 1fr; } }
</style>
