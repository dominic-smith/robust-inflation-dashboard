// Observable Framework prototype of the robust-inflation dashboard.
// R stays the compute layer: the data loaders in src/data/*.R read the validated
// CSVs in ../artifacts (written by compute/) at build time. The browser only
// receives static HTML, the chart library, and each page's own data.
export default {
  title: "Robust Measures of Inflation",
  root: "src",
  pages: [
    {name: "Latest reading", path: "/"},
    {name: "Best-trims range", path: "/best-trims-range"}
  ],
  theme: "air",
  toc: false,
  pager: false,
  search: false,
  footer: "Ocampo, Schoenle & Smith, “Robustness of Robust Measures of Inflation.” Computed from BEA underlying PCE detail (current vintage). Prototype."
};
