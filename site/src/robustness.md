---
title: Robustness
---

```js
import {TARGETS, SAMPLES} from "./components/style.js";
const heatFiles = {4: FileAttachment("data/heat-4.csv"), 5: FileAttachment("data/heat-5.csv")};
const refs = FileAttachment("data/heat-refs.csv").csv({typed: true});
const outline = FileAttachment("data/outline.csv").csv({typed: true});
```

# Which trims best track trend inflation?

<p class="muted">Every square is a trimmed mean, defined by how much it cuts from the low end (α) and the high end (β). The colour shows how well it tracks the chosen measure of trend inflation. The broad dark basin is the paper's key finding: a wide range of trims does about equally well, so the trimmed mean is robust. Results are from the paper's evaluation, fixed at the paper's data vintage.</p>

```js
const target = view(Inputs.radio(TARGETS, {label: "Trend measure", value: "c_0_37"}));
const sample = view(Inputs.radio(SAMPLES, {label: "Sample", value: "long"}));
const group = view(Inputs.radio(new Map([["All categories", 4], ["Excluding housing", 5]]), {label: "Categories", value: 4}));
const show = view(Inputs.radio(new Map([["Error relative to best trim", "rmse"], ["Statistical equivalence (DM test)", "dm"], ["Average bias", "bias"]]), {label: "Show", value: "rmse"}));
```

```js
const heat = heatFiles[group].csv({typed: true});   // the excluding-housing set loads only if chosen
```

```js
const panel = heat.filter((d) => d.sample === sample && d.target === target);
const ref = refs.filter((d) => d.group === group && d.sample === sample && d.target === target);
const best = show === "dm" ? {lb: ref[0].dm_best_lb, beta: ref[0].dm_best_beta} : {lb: ref[0].best_lb, beta: ref[0].best_beta};
const marks = [
  {label: "Headline", lb: 0, beta: 0}, {label: "Trimmed PCE", lb: 24, beta: 31},
  {label: "Median", lb: 50, beta: 50}, {label: "Trimmed CPI", lb: 8, beta: 8}
];
const DM_LABELS = {1: "p < 0.01", 2: "0.01–0.05", 3: "0.05–0.10 (equivalent)", 4: "≥ 0.10 (equivalent)"};
const view_ = {
  rmse: {cells: panel, fill: "rel", color: {type: "linear", scheme: "viridis", domain: [1, 2.5], label: "RMSE ÷ best", tickFormat: (v) => (v === 1 ? "best" : `${v}×`)},
         value: (d) => `RMSE ${d.rel.toFixed(2)}× the best trim`},
  dm:   {cells: panel.filter((d) => d.pcls != null), fill: "pcls",
         color: {type: "ordinal", domain: [1, 2, 3, 4], range: ["#F4F1E4", "#C6DBEF", "#6BAED6", "#08519C"], tickFormat: (v) => DM_LABELS[v], label: "DM test vs best"},
         value: (d) => `DM test vs best: ${DM_LABELS[d.pcls]}`},
  bias: {cells: panel.filter((d) => d.bias != null), fill: "bias",
         color: {type: "linear", domain: [0, 0.5], range: ["#008066", "#FFFF66"], label: "Average bias (pp)"},
         value: (d) => `Average bias ${d.bias.toFixed(2)} pp`}
}[show];
const noDM = show === "dm" && group === 5;
const segs = show === "bias" && group === 4 ? outline.filter((d) => d.sample === sample && d.target === target) : [];
```

<div class="grid grid-cols-3" style="grid-auto-rows: auto;">
  <div class="card grid-colspan-2">${noDM
    ? html`<p class="muted">Equivalence tests were run for the all-categories set only. Switch Categories to “All categories”.</p>`
    : resize((width) => Plot.plot({
      width: Math.min(width, 620), height: Math.min(width, 620) * 0.95,
      marginLeft: 50, marginBottom: 45,
      x: {domain: [-0.5, 50.5], label: "Lower trim α (%)", ticks: d3.range(0, 51, 10)},
      y: {domain: [-0.5, 50.5], label: "Upper trim β (%)", ticks: d3.range(0, 51, 10)},
      color: {...view_.color, legend: true},
      symbol: {legend: true, domain: marks.map((m) => m.label), range: ["circle", "diamond", "square", "triangle"]},
      marks: [
        Plot.rect(view_.cells, {x1: (d) => d.lb - 0.5, x2: (d) => d.lb + 0.5, y1: (d) => d.beta - 0.5, y2: (d) => d.beta + 0.5, fill: view_.fill}),
        Plot.link([0], {x1: 0, y1: 0, x2: 50, y2: 50, stroke: show === "rmse" ? "#ddd" : "#999", strokeDasharray: "4,4"}),
        Plot.link(segs, {x1: "x1", y1: "y1", x2: "x2", y2: "y2", stroke: "#111", strokeWidth: 1.4}),
        Plot.dot(marks, {x: "lb", y: "beta", symbol: "label", fill: "white", stroke: "#222", strokeWidth: 1.2, r: 5}),   // visible on dark cells and in the legend
        Plot.dot([best], {x: "lb", y: "beta", symbol: "star", fill: "#FFD700", stroke: "#7a6200", r: 9}),
        Plot.tip(view_.cells, Plot.pointer({x: "lb", y: "beta", title: (d) => `Trim α = ${d.lb}%, β = ${d.beta}%\n${view_.value(d)}`}))
      ]
    }))}</div>
  <div class="card">
    <h2>RMSE vs the trend measure</h2>
    <table class="refs"><tbody>${["Headline PCE", "Core PCE", "Median PCE", "Trimmed mean", "NY Fed UIG", "Best trim"].map((m) => {
      const r = ref.find((x) => x.measure === m);
      return html`<tr><td>${m}${m === "Best trim" ? html` <span class="muted">(${best.lb}/${best.beta})</span>` : ""}</td><td>${r ? r.rmse.toFixed(2) : "–"}</td></tr>`;
    })}</tbody></table>
    <p class="muted">${{
      rmse: "Colour: each trim's RMSE divided by the best trim's RMSE.",
      dm: "Colour: Diebold–Mariano test p-value comparing each trim's errors with the best trim's. p ≥ 0.05 = statistically equivalent; that set defines the Best-trims range page.",
      bias: group === 4 ? "Colour: square root of each trim's average squared bias against the trend measure (pp); trims with bias of 0.5 pp or more are left blank. Outlined: trims not statistically worse than the best at the 1% level (DM p ≥ 0.01), as in the paper."
                        : "Colour: square root of each trim's average squared bias (pp); trims with bias of 0.5 pp or more are left blank. The DM outline is available for all categories only."
    }[show]}</p>
  </div>
</div>

<style>
table.refs { width: 100%; max-width: none; font-size: 14px; }
table.refs td:last-child { text-align: right; font-variant-numeric: tabular-nums; }
</style>
