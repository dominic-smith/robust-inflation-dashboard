// Palette, labels and number formats shared by every page.
//
// Colours follow the dataviz skill's reference palette. Categorical slots 1-3 (blue,
// orange, aqua) were run through validate_palette.js and pass the all-pairs CVD and
// normal-vision checks in light and dark mode. Light-mode aqua is below 3:1 on the
// surface, so every chart carries direct labels and a table view. Headline PCE is the
// de-emphasis grey: it is context, the robust measures are the subject.
// The DM-test ramp was validated as an ordinal scale (--ordinal) in both modes.

export const MEASURES = ["Trimmed-mean PCE", "Median PCE", "Core PCE", "Headline PCE"];
export const KEY = {"Trimmed-mean PCE": "tm", "Median PCE": "median", "Core PCE": "core", "Headline PCE": "headline"};

const BLUE = ["#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5",
              "#2a78d6", "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b"];

const LIGHT = {
  dark: false,
  ink: "#0b0b0b", ink2: "#52514e", muted: "#898781", grid: "#e1e0d9", axis: "#c3c2b7",
  surface: "#fcfcfb", neutral: "#f0efec",
  series: {"Trimmed-mean PCE": "#2a78d6", "Median PCE": "#eb6834", "Core PCE": "#1baf7a", "Headline PCE": "#898781"},
  band: "#52514e",          // best-trims range: ink wash; its average is drawn in ink
  star: "#eda100",          // best trim marker (categorical slot 4, not a status colour)
  ramp: BLUE,               // sequential, weakest -> strongest ("darker = better")
  dm: ["#f0efec", "#86b6ef", "#2a78d6", "#104281"]   // not equivalent, then ordinal blue
};

const DARK = {
  dark: true,
  ink: "#ffffff", ink2: "#c3c2b7", muted: "#898781", grid: "#2c2c2a", axis: "#383835",
  surface: "#1a1a19", neutral: "#383835",
  series: {"Trimmed-mean PCE": "#3987e5", "Median PCE": "#d95926", "Core PCE": "#199e70", "Headline PCE": "#898781"},
  band: "#c3c2b7",
  star: "#c98500",
  ramp: [...BLUE].reverse(),  // on the dark surface the strongest step is the lightest
  dm: ["#383835", "#184f95", "#3987e5", "#86b6ef"]
};

export const palette = (dark) => (dark ? DARK : LIGHT);

export const HORIZONS = new Map([["12-month", "12m"], ["3-month", "3m"], ["1-month", "1m"]]);
export const horizonText = {"12m": "12-month change", "3m": "3-month change, annualized", "1m": "1-month change, annualized"};

// The paper's trend measures and the samples its trim sets were chosen on
export const TARGETS = new Map([
  ["Current trend", "c_0_37"],
  ["Future trend", "f_12_24"],
  ["Forward trend", "f_0_24"],
  ["Band-pass trend", "b_2_39"]
]);
export const TARGET_NOTE = {
  c_0_37: "a 37-month centered average of headline inflation",
  f_12_24: "headline inflation 12 to 24 months ahead",
  f_0_24: "headline inflation over the next 24 months",
  b_2_39: "a band-pass filter of headline inflation (2- to 39-month cycles)"
};
export const SAMPLES = new Map([["1970–2024", "long"], ["1970–1989", "80s"], ["2000–2024", "00s"]]);

const MINUS = "−";
const num = (x, d) => (x < 0 ? MINUS : "") + Math.abs(x).toFixed(d);
export const fmt = {
  pct: (x, d = 1) => (x == null || Number.isNaN(x) ? "–" : `${num(x, d)}%`),
  signed: (x, d = 1) => (x == null || Number.isNaN(x) ? "–" : `${x > 0 ? "+" : ""}${num(x, d)}`),
  pp: (x, d = 1) => (x == null || Number.isNaN(x) ? "–" : `${x > 0 ? "+" : ""}${num(x, d)} pp`),
  month: (d) => d.toLocaleDateString("en-US", {month: "long", year: "numeric", timeZone: "UTC"}),
  monthShort: (d) => d.toLocaleDateString("en-US", {month: "short", year: "numeric", timeZone: "UTC"}),
  ym: (d) => d.toISOString().slice(0, 7)
};

// A month n months before d (UTC, first of month)
export const monthsBefore = (d, n) => new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() - n, 1));
