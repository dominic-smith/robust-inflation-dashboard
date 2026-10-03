// Shared labels, colours and formatters (mirrors app/R/theme_dashboard.R)
import * as Inputs from "npm:@observablehq/inputs";
export const MEASURES = ["Headline PCE", "Core PCE", "Cleveland median", "Dallas trimmed mean"];
export const COLORS = ["#7F7F7F", "#0072B2", "#D55E00", "#009E73"];   // Okabe-Ito; headline muted
export const colorOf = (m) => COLORS[MEASURES.indexOf(m)];

export const HORIZONS = new Map([["1-month", "1m"], ["3-month", "3m"], ["12-month", "12m"]]);
export const horizonLabel = (h) => ({"1m": "1-month change, annualized", "3m": "3-month change, annualized", "12m": "12-month change"})[h];

export const TARGETS = new Map([
  ["Current trend (centered)", "c_0_37"],
  ["Future trend (12–24m ahead)", "f_12_24"],
  ["Forward trend (0–24m)", "f_0_24"],
  ["Band-pass trend (2–39m)", "b_2_39"]
]);
export const SAMPLES = new Map([["1970–2024", "long"], ["1970–1989", "80s"], ["2000–2024", "00s"]]);

export const pct = (x) => (x == null || Number.isNaN(x) ? "–" : `${x.toFixed(1)}%`);
export const monthLabel = (d) => d.toLocaleDateString("en-US", {month: "long", year: "numeric", timeZone: "UTC"});

// Horizon selector shared across pages: remembers the visitor's choice for the
// session (the Shiny app had one global lever), falls back to 12-month.
export function horizonInput() {
  let init = "12m";
  try { init = sessionStorage.getItem("rrm-horizon") ?? "12m"; } catch {}
  if (!["1m", "3m", "12m"].includes(init)) init = "12m";
  const input = Inputs.radio(HORIZONS, {label: "Horizon", value: init});
  input.addEventListener("input", () => { try { sessionStorage.setItem("rrm-horizon", input.value); } catch {} });
  return input;
}
export const changeLabel = (h) => (h === "12m" ? "12-month change" : `${h === "1m" ? "1" : "3"}-month change, annualized`);
