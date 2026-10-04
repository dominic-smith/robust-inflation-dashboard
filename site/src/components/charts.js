// Chart and figure builders shared by the pages.
//
// Specs follow the dataviz skill: 2px lines with round joins, end dots with a 2px
// surface ring, solid hairline grid, areas as washes, text in ink tokens (never the
// series colour), a legend for >= 2 series plus selective direct labels at line ends,
// a crosshair tooltip listing every series at the hovered month, and a table view.
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
import {html, svg} from "npm:htl";
import {fmt} from "./theme.js";

export const plotStyle = (c) => ({fontFamily: "var(--sans-serif)", fontSize: "12px", color: c.ink2, background: "transparent", overflow: "visible"});
const tipStyle = (c) => ({fill: c.surface, stroke: c.axis, textPadding: 8, fontSize: 12});

// Legend whose keys mirror the marks: line keys for lines, rect keys for areas
export function legend(items) {
  return html`<div class="legend">${items.map(({label, kind = "line", color}) => html`<span>${swatch(kind, color)}${label}</span>`)}</div>`;
}
const SYMBOLS = {circle: d3.symbolCircle, diamond: d3.symbolDiamond, square: d3.symbolSquare, triangle: d3.symbolTriangle, star: d3.symbolStar};
function swatch(kind, color) {
  if (SYMBOLS[kind]) {
    const path = d3.symbol(SYMBOLS[kind], kind === "star" ? 110 : 60)();
    return kind === "star"
      ? svg`<svg width="14" height="14" viewBox="-7 -7 14 14" aria-hidden="true"><path d=${path} fill=${color}/></svg>`
      : svg`<svg width="14" height="14" viewBox="-7 -7 14 14" aria-hidden="true"><path d=${path} fill="none" stroke=${color} stroke-width="1.4"/></svg>`;
  }
  if (kind === "area") return svg`<svg width="16" height="10" aria-hidden="true"><rect width="16" height="10" rx="2" fill=${color} fill-opacity="0.25"/></svg>`;
  if (kind === "dot") return svg`<svg width="10" height="10" aria-hidden="true"><circle cx="5" cy="5" r="4" fill=${color}/></svg>`;
  if (kind === "hollow") return svg`<svg width="10" height="10" aria-hidden="true"><circle cx="5" cy="5" r="3.5" fill="none" stroke=${color} stroke-width="1.8"/></svg>`;
  if (kind === "rule") return svg`<svg width="16" height="10" aria-hidden="true"><line x1="0" x2="16" y1="5" y2="5" stroke=${color} stroke-width="1" stroke-opacity="0.7"/></svg>`;
  return svg`<svg width="16" height="10" aria-hidden="true"><line x1="1" x2="15" y1="5" y2="5" stroke=${color} stroke-width="2.5" stroke-linecap="round"/></svg>`;
}

// Time-series chart: optional band (area) + lines, a target line, direct end labels and
// a crosshair tooltip.
//   lines: [{label, color, rows: [{date, value}], strokeWidth?}]
//   band:  {label, color, rows: [{date, lo, hi}], opacity?}
//   unit:  "%" (default) or " pp";  keys: legend items, to override the default
export function timeChart({lines = [], band = null, target = 2, width, height = 340, c, endLabels = true, unit = "%", keys = null}) {
  const narrow = width < 560;
  const showLabels = endLabels && !narrow && lines.length > 0;
  const marginTop = 14, marginBottom = 28, marginLeft = 42;
  const marginRight = showLabels ? 170 : 14;

  const values = [
    ...lines.flatMap((l) => l.rows.map((r) => r.value)),
    ...(band ? band.rows.flatMap((r) => [r.lo, r.hi]) : []),
    ...(target != null ? [target] : [])
  ].filter((v) => v != null && Number.isFinite(v));
  const [v0, v1] = d3.extent(values);
  const pad = (v1 - v0) * 0.06 || 0.5;
  const yDomain = [v0 - pad, v1 + pad];
  const xDomain = d3.extent([...lines.flatMap((l) => l.rows.map((r) => r.date)), ...(band ? band.rows.map((r) => r.date) : [])]);

  // End labels: placed in pixel space, at least 16px apart; a leader connects a label
  // that had to move to its line end (labels are never just nudged and left detached).
  const ys = Plot.scale({y: {domain: yDomain, range: [height - marginBottom, marginTop]}});
  const ends = lines
    .filter((l) => l.rows.length)
    .map((l) => {
      const last = l.rows[l.rows.length - 1];
      return {date: last.date, v: last.value, label: l.label, color: l.color, py: ys.apply(last.value)};
    })
    .sort((a, b) => a.py - b.py);
  for (let i = 1; i < ends.length; ++i) if (ends[i].py - ends[i - 1].py < 16) ends[i].py = ends[i - 1].py + 16;
  const overflow = ends.length ? ends[ends.length - 1].py - (height - marginBottom) : 0;
  if (overflow > 0) for (const e of ends) e.py -= overflow;
  for (const e of ends) e.ly = ys.invert(e.py);

  // One tooltip per month listing every series; values lead, labels follow
  const byDate = new Map();
  const add = (date, item) => {
    const k = +date;
    if (!byDate.has(k)) byDate.set(k, {date, items: []});
    byDate.get(k).items.push(item);
  };
  const show = (v, d = 2) => (unit === "%" ? fmt.pct(v, d) : `${v.toFixed(d)}${unit}`);
  if (band) for (const r of band.rows) add(r.date, {text: `${r.lo.toFixed(2)}–${r.hi.toFixed(2)}${unit}  ${band.label}`, top: r.hi});
  for (const l of lines) for (const r of l.rows) if (r.value != null) add(r.date, {text: `${show(r.value)}  ${l.label}`, top: r.value});
  const tipRows = [...byDate.values()]
    .map(({date, items}) => ({date, top: d3.max(items, (i) => i.top), text: `${fmt.month(date)}\n${items.map((i) => i.text).join("\n")}`}))
    .sort((a, b) => a.date - b.date);

  const marks = [];
  if (band) marks.push(Plot.areaY(band.rows, {x: "date", y1: "lo", y2: "hi", fill: band.color, fillOpacity: band.opacity ?? 0.16}));
  // The target is a thin ink rule identified in the legend (an in-plot label collides with
  // series that sit near 2%, which they often do)
  if (target != null) marks.push(Plot.ruleY([target], {stroke: c.ink2, strokeWidth: 1, strokeOpacity: 0.7}));
  for (const l of lines) {
    marks.push(Plot.lineY(l.rows, {x: "date", y: "value", stroke: l.color, strokeWidth: l.strokeWidth ?? 2, strokeLinejoin: "round", strokeLinecap: "round"}));
  }
  if (showLabels) {
    marks.push(Plot.link(ends.filter((e) => Math.abs(e.ly - e.v) > 1e-9), {x1: "date", x2: "date", y1: "v", y2: "ly", stroke: c.axis, dx: 9}));
    marks.push(Plot.dot(ends, {x: "date", y: "v", fill: (e) => e.color, r: 4, stroke: c.surface, strokeWidth: 2}));
    marks.push(Plot.text(ends, {x: "date", y: "ly", text: (e) => `${show(e.v, 1)}  ${e.label}`, dx: 14, textAnchor: "start", fill: c.ink, fontSize: 12}));
  }
  marks.push(Plot.ruleX(tipRows, Plot.pointerX({x: "date", stroke: c.muted, strokeWidth: 1})));
  marks.push(Plot.tip(tipRows, Plot.pointerX({x: "date", y: "top", title: "text", ...tipStyle(c)})));

  const chart = Plot.plot({
    width, height, marginTop, marginBottom, marginLeft, marginRight,
    style: plotStyle(c),
    x: {type: "utc", domain: xDomain, label: null, ticks: narrow ? 4 : 8},
    y: {domain: yDomain, label: null, grid: true, ticks: 6, tickFormat: (d) => `${d}${unit}`},
    color: {type: "identity"},
    marks
  });
  keys ??= [...(band ? [{label: band.label, kind: "area", color: band.color}] : []), ...lines.map((l) => ({label: l.label, kind: "line", color: l.color}))];
  if (target != null) keys = [...keys, {label: `${target}% target`, kind: "rule", color: c.ink2}];
  return html`<div>${legend(keys)}${chart}</div>`;
}

// Momentum: 12-month rate (hollow) vs last-3-months annualized rate (filled), per measure
export function momentumChart(rows, {width, c}) {
  const height = 44 * rows.length + 34;
  const [lo, hi] = d3.extent([...rows.flatMap((r) => [r.m12, r.m3]), 2]);
  const pad = (hi - lo) * 0.15 + 0.25;
  const up = rows.filter((r) => r.m3 >= r.m12), down = rows.filter((r) => r.m3 < r.m12);
  const color = (r) => c.series[r.measure];
  return html`<div>${legend([{label: "Last 12 months", kind: "hollow", color: c.ink2}, {label: "Last 3 months, annualized", kind: "dot", color: c.ink2}, {label: "2% target", kind: "rule", color: c.ink2}])}${Plot.plot({
    width, height, marginLeft: 128, marginRight: 16, marginTop: 6, marginBottom: 28,
    style: plotStyle(c),
    x: {domain: [lo - pad, hi + pad], grid: true, label: null, ticks: 4, tickFormat: (d) => `${d}%`},
    y: {domain: rows.map((r) => r.measure), label: null, tickSize: 0, padding: 0.5},
    color: {type: "identity"},
    marks: [
      Plot.ruleX([2], {stroke: c.ink2, strokeWidth: 1, strokeOpacity: 0.7}),
      Plot.link(rows, {x1: "m12", x2: "m3", y: "measure", stroke: color, strokeWidth: 2, strokeOpacity: 0.45}),
      Plot.dot(rows, {x: "m12", y: "measure", r: 5, fill: c.surface, stroke: color, strokeWidth: 2}),
      Plot.dot(rows, {x: "m3", y: "measure", r: 5.5, fill: color, stroke: c.surface, strokeWidth: 2}),
      Plot.text(up, {x: "m3", y: "measure", text: (r) => fmt.pct(r.m3), dx: 11, textAnchor: "start", fill: c.ink, fontSize: 12}),
      Plot.text(down, {x: "m3", y: "measure", text: (r) => fmt.pct(r.m3), dx: -11, textAnchor: "end", fill: c.ink, fontSize: 12}),
      Plot.tip(rows, Plot.pointerY({y: "measure", x: "m3", title: (r) => `${r.measure}\n${fmt.pct(r.m12, 2)}  last 12 months\n${fmt.pct(r.m3, 2)}  last 3 months, annualized`, ...tipStyle(c)}))
    ]
  })}</div>`;
}

// Table of categories with an inline contribution bar
export function contributionTable(rows, {maxAbs, changeLabel = "Change", compact = false} = {}) {
  const m = maxAbs ?? (d3.max(rows, (r) => Math.abs(r.contribution)) || 1);
  return html`<table>
    <thead><tr><th>Category</th><th class="num">${changeLabel}</th>${compact ? null : html`<th class="num">Share of spending</th>`}<th class="bar-cell">${compact ? "Pull on headline" : "Approx. contribution to headline"}</th></tr></thead>
    <tbody>${rows.map((r) => html`<tr>
      <td>${r.category}</td>
      <td class="num">${fmt.signed(r.change)}%</td>
      ${compact ? null : html`<td class="num">${r.weight.toFixed(1)}%</td>`}
      <td class="bar-cell"><div class="bar-row"><div class="bar-track"><div class="bar" style=${{width: `${(100 * Math.abs(r.contribution)) / m}%`}}></div></div><span class="num">${fmt.pp(r.contribution, 2)}</span></div></td>
    </tr>`)}</tbody>
  </table>`;
}

// Stat tile: label (with a series key), value, optional sub-line, delta and sparkline
export function statTile({label, keyClass, value, sub, delta, spark, hero = false}) {
  return html`<div class=${hero ? "tile hero" : "tile"}>
    <div class="label">${keyClass ? html`<span class=${`dot ${keyClass}`}></span>` : null}${label}</div>
    <div class="value">${value}</div>
    ${sub ? html`<div class="range">${sub}</div>` : null}
    ${delta ? html`<div class="delta">${delta}</div>` : null}
    ${spark ?? null}
  </div>`;
}

// Change vs n months earlier, as an arrow + neutral text (inflation direction is not
// coloured good/bad here)
export function deltaText(now, then, sinceLabel) {
  if (now == null || then == null) return null;
  const d = now - then;
  const arrow = Math.abs(d) < 0.05 ? "→" : d > 0 ? "↑" : "↓";
  return `${arrow} ${Math.abs(d).toFixed(1)} pp since ${sinceLabel}`;
}

// Sparkline coloured by a CSS series class (so it follows light/dark mode)
export function sparkline(values, keyClass, {width = 160, height = 30} = {}) {
  const v = values.filter((x) => x != null && Number.isFinite(x));
  if (v.length < 2) return null;
  const [lo, hi] = d3.extent(v);
  const span = hi - lo || 1;
  const pts = v.map((x, i) => [3 + (i / (v.length - 1)) * (width - 8), 4 + (1 - (x - lo) / span) * (height - 8)]);
  const d = `M${pts.map((p) => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join("L")}`;
  const [lx, ly] = pts[pts.length - 1];
  return svg`<svg class=${`spark ${keyClass}`} width=${width} height=${height} viewBox=${`0 0 ${width} ${height}`} role="img" aria-label=${`Last ${v.length} months`}><path d=${d}/><circle cx=${lx} cy=${ly} r="3.5"/></svg>`;
}

// Collapsible table view: the accessible twin of a chart
export function tableView(columns, rows, {summary = "View as table"} = {}) {
  return html`<details class="table-view"><summary>${summary}</summary><div class="table-scroll"><table>
    <thead><tr>${columns.map((col) => html`<th class=${col.num ? "num" : ""}>${col.label}</th>`)}</tr></thead>
    <tbody>${rows.map((r) => html`<tr>${columns.map((col) => html`<td class=${col.num ? "num" : ""}>${col.value(r)}</td>`)}</tr>`)}</tbody>
  </table></div></details>`;
}
