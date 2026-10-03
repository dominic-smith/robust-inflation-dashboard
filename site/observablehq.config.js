// Observable Framework prototype of the robust-inflation dashboard.
// R stays the compute layer: the data loaders in src/data/*.R read the validated
// CSVs in ../artifacts (written by compute/) at build time. The browser only
// receives static HTML, the chart library, and each page's own data.
export default {
  title: "Robust Measures of Inflation",
  root: "src",
  pages: [
    {name: "Latest reading", path: "/"},
    {name: "Best-trims range", path: "/best-trims-range"},
    {name: "Measure disagreement", path: "/measure-disagreement"},
    {name: "Distribution", path: "/distribution"},
    {name: "Robustness", path: "/robustness"},
    {name: "Download & methods", path: "/download"}
  ],
  theme: "air",
  // The air theme's serif face (Source Serif 4, SIL OFL) is served from this site
  // (src/fonts, copied into dist by the build script) instead of Google Fonts, so a
  // page load makes no third-party request. Relative URLs work because every page is
  // at the site's top level (also under a subfolder such as /proto/).
  globalStylesheets: [],
  // (No <link rel=preload>: Framework rewrites that href to a hashed copy, which made
  // browsers download the font twice. font-display: swap keeps text visible meanwhile.)
  head: `<style>
@font-face { font-family: "Source Serif 4"; font-style: normal; font-weight: 200 900; font-display: swap;
  src: url("./fonts/source-serif-4-latin-wght-normal.woff2") format("woff2"); }
@font-face { font-family: "Source Serif 4"; font-style: italic; font-weight: 200 900; font-display: swap;
  src: url("./fonts/source-serif-4-latin-wght-italic.woff2") format("woff2"); }
</style>`,
  toc: false,
  pager: false,
  search: false,
  footer: "Ocampo, Schoenle & Smith, “Robustness of Robust Measures of Inflation.” Computed from BEA underlying PCE detail (current vintage)."
};
