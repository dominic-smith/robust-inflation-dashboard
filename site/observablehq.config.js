// Robust Measures of Inflation: Observable Framework configuration.
//
// R is the compute layer: compute/ writes and validates ../artifacts, and the data
// loaders (src/data/*.R) and the Overview page loader (src/index.md.R) read those CSVs at
// build time. The browser receives static HTML, the chart library, and only the data
// for what is on screen.
import {readFileSync} from "node:fs";

const vintage = JSON.parse(readFileSync(new URL("../artifacts/vintage.json", import.meta.url), "utf8"));
const updated = new Date(vintage.refreshed_at).toLocaleDateString("en-US", {month: "long", day: "numeric", year: "numeric"});

// Inline icon: no extra request (and no 404 for /favicon.ico)
const icon = "data:image/svg+xml," + encodeURIComponent(
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><rect x="1" y="8" width="3.5" height="7" rx="1" fill="#898781"/><rect x="6.25" y="3" width="3.5" height="12" rx="1" fill="#2a78d6"/><rect x="11.5" y="6" width="3.5" height="9" rx="1" fill="#2a78d6"/></svg>`
);

export default {
  title: "Robust Measures of Inflation",
  root: "src",
  style: "style.css",        // our tokens on Framework's layout; system fonts only
  globalStylesheets: [],     // drop Framework's default Google Fonts link: no third-party requests
  pages: [
    {name: "Overview", path: "/"},
    {name: "Underlying inflation range", path: "/trend-range"},
    {name: "The four measures", path: "/measures"},
    {name: "What's driving it", path: "/drivers"},
    {name: "Do the measures agree?", path: "/agreement"},
    {name: "Why trimmed means are robust", path: "/robustness"},
    {name: "Data and methods", path: "/data"}
  ],
  head: `<link rel="icon" href="${icon}">
<meta name="description" content="Robust measures of US inflation (trimmed-mean and median PCE) and the range of underlying inflation supported by the best trims, updated monthly from BEA data.">
<meta name="robots" content="noindex">`,
  header: `<div class="vintage"><span>Data through <b>${vintage.vintage_label}</b></span><span>Updated ${updated}</span></div>`,
  footer: `Ocampo, Schoenle and Smith, “Robustness of Robust Measures of Inflation,” <i>International Journal of Central Banking</i>, forthcoming. Computed from BEA's detailed PCE data; an independent research companion, not an official statistic.`,
  toc: false,
  pager: false,
  search: false,
  sidebar: true
};
