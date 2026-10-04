# Overview page (a Framework page loader: this script prints the page's Markdown).
#
# Written for a policymaker: the answer first (where underlying inflation is, against
# the 2% target, which way it is moving, and what is driving headline), then the detail.
# Everything above the charts is computed here at build time and emitted as plain HTML,
# so it is on screen before any JavaScript runs; the charts use a small inline dataset
# (no extra requests).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "data", "artifacts.R"))

s <- artifact("series_h.csv"); s$date <- as.Date(s$date)
b <- artifact("best_trims_band.csv"); b$date <- as.Date(b$date)
dist <- artifact("distribution_h.csv")
vin <- artifact("vintage.json")

band <- b[b$target == "c_0_37" & b$sample == "long", ]; band <- band[order(band$date), ]
last <- max(band$date)
stopifnot(last == max(s$date[s$horizon == "12m"]))
ago <- function(n) seq(last, by = paste0("-", n, " months"), length.out = 2)[2]
val <- function(m, h = "12m", date = last) { x <- s$value[s$measure == m & s$horizon == h & s$date == date]; if (length(x)) x else NA }
at <- function(date, col) band[[col]][band$date == date]

f1 <- function(x) sub("^-", "−", sprintf("%.1f", x))
f2 <- function(x) sub("^-", "−", sprintf("%.2f", x))
mon <- function(d) format(d, "%B %Y")
esc <- function(x) gsub("&", "&amp;", gsub("<", "&lt;", x, fixed = TRUE), fixed = TRUE)

tr <- at(last, "mean"); lo <- at(last, "lo"); hi <- at(last, "hi"); n_trims <- band$n_trims[1]
tr3 <- at(ago(3), "mean"); tr12 <- at(ago(12), "mean")
H <- val("Headline PCE")
m12 <- val("Trimmed-mean PCE"); m3 <- val("Trimmed-mean PCE", "3m")

# --- what is pushing headline away from trend: categories the trimmed mean sets aside
dd <- dist[dist$horizon == "12m", ]; dd <- dd[order(dd$rate), ]
dd$cumw <- cumsum(dd$weight) / sum(dd$weight)
lo_cut <- max(dd$rate[dd$cumw <= 0.24]); hi_cut <- min(dd$rate[dd$cumw >= 0.69])
dd$contribution <- dd$weight * dd$rate
dd$category <- clean_category(dd$category)
up <- dd[dd$rate > hi_cut, ]; up <- up[order(-up$contribution), ]
down <- dd[dd$rate < lo_cut, ]; down <- down[order(down$contribution), ]
lc <- function(x) paste0(tolower(substr(x, 1, 1)), substring(x, 2))
item <- function(r, first) sprintf("%s (%s%s%%%s, about %s pp of headline)", esc(lc(r$category)), if (r$rate > 0) "+" else "",
                                    f1(r$rate), if (first) " over the year" else "", sub("^([0-9])", "+\\1", f2(r$contribution)))
pair <- function(t) paste(item(t[1, ], TRUE), "and", item(t[2, ], FALSE))

# --- the narrative (templated from the numbers; no judgement beyond the thresholds)
p_level <- sprintf("Across the %d trimmed means that track trend inflation best, the 12-month rate in %s ranges from %s%% to %s%%%s.",
                   n_trims, mon(last), f1(lo), f1(hi),
                   if (lo > 2) ", entirely above the 2% target" else if (hi < 2) ", entirely below the 2% target" else ", straddling the 2% target")
d12 <- tr - tr12
p_dir <- if (abs(d12) < 0.1) sprintf("Their average, %s%%, is little changed from a year earlier.", f1(tr)) else
  sprintf("Their average, %s%%, is %s from %s%% a year earlier.", f1(tr), if (d12 < 0) "down" else "up", f1(tr12))
mom <- m3 - m12
p_mom <- sprintf("%s: over the past three months the trimmed mean rose at a %s%% annual rate, %s its 12-month pace of %s%%.",
                 if (mom <= -0.25) "Momentum has slowed" else if (mom >= 0.25) "Momentum has picked up" else "Momentum is steady",
                 f1(m3), if (mom <= -0.25) "below" else if (mom >= 0.25) "above" else "close to", f1(m12))
p_head <- if (H > hi) sprintf("Headline PCE inflation, at %s%%, is above the range. The largest upward pushes come from categories the trimmed mean sets aside: %s.", f1(H), pair(up)) else
  if (H < lo) sprintf("Headline PCE inflation, at %s%%, is below the range. The largest downward pushes come from categories the trimmed mean sets aside: %s.", f1(H), pair(down)) else
  sprintf("Headline PCE inflation, at %s%%, is inside the range.", f1(H))

# --- static stat tiles with sparklines (last 24 months), coloured by CSS series classes
spark <- function(v, cls, w = 160, h = 30) {
  v <- v[is.finite(v)]; r <- range(v); span <- if (diff(r) > 0) diff(r) else 1
  x <- 3 + (seq_along(v) - 1) / (length(v) - 1) * (w - 8); y <- 4 + (1 - (v - r[1]) / span) * (h - 8)
  sprintf('<svg class="spark %s" width="%d" height="%d" viewBox="0 0 %d %d" role="img" aria-label="Last %d months"><path d="M%s"/><circle cx="%.1f" cy="%.1f" r="3.5"/></svg>',
          cls, w, h, w, h, length(v), paste(sprintf("%.1f,%.1f", x, y), collapse = "L"), tail(x, 1), tail(y, 1))
}
since <- format(ago(3), "%b %Y")
delta <- function(now, then) { d <- now - then
  sprintf("%s %s pp since %s", if (abs(d) < 0.05) "→" else if (d > 0) "↑" else "↓", sprintf("%.1f", abs(d)), since) }
last24 <- function(m) { x <- s[s$measure == m & s$horizon == "12m" & s$date > ago(24), ]; x$value[order(x$date)] }
tile <- function(m, cls) sprintf('<div class="tile"><div class="label"><span class="dot %s"></span>%s</div><div class="value">%s%%</div><div class="delta">%s</div>%s</div>',
                                 cls, m, f1(val(m)), delta(val(m), val(m, date = ago(3))), spark(last24(m), cls))
hero <- sprintf('<div class="tile hero"><div class="label">Best-trims average · underlying inflation</div><div class="value">%s%%</div><div class="range">Range of the best trims: <b>%s–%s%%</b></div><div class="delta">%s</div>%s</div>',
                f1(tr), f1(lo), f1(hi), delta(tr, tr3), spark(band$mean[band$date > ago(24)], "k-band", 320))

# --- inline data for the charts
since2019 <- band$date >= as.Date("2019-01-01")
hl <- s[s$measure == "Headline PCE" & s$horizon == "12m" & s$date >= as.Date("2019-01-01"), ]
tmd <- s[s$measure == "Trimmed-mean PCE" & s$horizon == "12m" & s$date >= as.Date("2019-01-01"), ]
ov <- list(
  trend = data.frame(date = format(band$date[since2019]), lo = r6(band$lo[since2019]), hi = r6(band$hi[since2019]), mean = r6(band$mean[since2019])),
  headline = data.frame(date = format(hl$date[order(hl$date)]), value = r6(hl$value[order(hl$date)])),
  trimmed = data.frame(date = format(tmd$date[order(tmd$date)]), value = r6(tmd$value[order(tmd$date)])),
  momentum = data.frame(measure = c("Trimmed-mean PCE", "Median PCE", "Core PCE", "Headline PCE"),
                        m12 = r6(sapply(c("Trimmed-mean PCE", "Median PCE", "Core PCE", "Headline PCE"), val)),
                        m3 = r6(sapply(c("Trimmed-mean PCE", "Median PCE", "Core PCE", "Headline PCE"), val, h = "3m"))),
  up = data.frame(category = up$category[1:5], change = r6(up$rate[1:5]), weight = r6(100 * up$weight[1:5]), contribution = r6(up$contribution[1:5])),
  down = data.frame(category = down$category[1:4], change = r6(down$rate[1:4]), weight = r6(100 * down$weight[1:4]), contribution = r6(down$contribution[1:4])),
  n_trims = n_trims, month = format(last)
)
json <- jsonlite::toJSON(ov, dataframe = "rows", auto_unbox = TRUE, digits = 6)

cat(sprintf('---
title: Overview
---

```js
import {palette, fmt} from "./components/theme.js";
import {timeChart, momentumChart, contributionTable, tableView} from "./components/charts.js";
const OV = %s;
const asDates = (rows) => rows.map((d) => ({...d, date: new Date(d.date)}));
const trend = asDates(OV.trend), headline = asDates(OV.headline), trimmed = asDates(OV.trimmed);
```

```js
const c = palette(dark);
```

<p class="eyebrow">Underlying PCE inflation · %s</p>

# Underlying inflation is running at about %s%%

<p class="lede">%s %s %s %s</p>

<div class="tiles lead">
%s
%s
%s
%s
%s
</div>

<div class="card">
  <h3>Underlying and headline inflation since 2019</h3>
  <p class="sub">12-month change. The shaded band is the range of the %d best trims; the dark line is their average.</p>
  ${resize((width) => timeChart({c, width, height: 340,
    band: {label: "Range of best trims", color: c.band, rows: trend, opacity: 0.17},
    lines: [
      {label: "Best-trims average", color: c.ink, rows: trend.map((d) => ({date: d.date, value: d.mean}))},
      {label: "Trimmed-mean PCE", color: c.series["Trimmed-mean PCE"], rows: trimmed},
      {label: "Headline PCE", color: c.series["Headline PCE"], rows: headline}
    ]}))}
  ${tableView([
    {label: "Month", value: (d) => fmt.ym(d.date)},
    {label: "Best trims, low", num: true, value: (d) => d.lo.toFixed(2)},
    {label: "Best trims, high", num: true, value: (d) => d.hi.toFixed(2)},
    {label: "Average", num: true, value: (d) => d.mean.toFixed(2)},
    {label: "Headline PCE", num: true, value: (d) => headline.find((h) => +h.date === +d.date)?.value.toFixed(2) ?? "–"}
  ], [...trend].reverse())}
</div>

<div class="two-up wide-right">
  <div class="card">
    <h3>Is inflation speeding up or slowing down?</h3>
    <p class="sub">Each measure over the last 12 months (hollow) and the last 3 months at an annual rate (filled).</p>
    ${resize((width) => momentumChart(OV.momentum, {width, c}))}
    ${tableView([
      {label: "Measure", value: (d) => d.measure},
      {label: "12 months", num: true, value: (d) => d.m12.toFixed(2)},
      {label: "3 months, annualized", num: true, value: (d) => d.m3.toFixed(2)}
    ], OV.momentum)}
  </div>
  <div class="card">
    <h3>What the trimmed mean sets aside</h3>
    <p class="sub">Categories with the most extreme 12-month price changes, which the trimmed mean drops, ranked by their approximate pull on headline (share of spending × price change).</p>
    ${contributionTable([...OV.up, ...OV.down], {compact: true})}
  </div>
</div>

## Explore

<div class="explore">
  <a href="./trend-range"><strong>Underlying inflation range →</strong><span>The paper\'s Figure 1, updated monthly, for each measure of trend inflation.</span></a>
  <a href="./measures"><strong>The four measures →</strong><span>Headline, core, median and trimmed mean over 1, 3 and 12 months.</span></a>
  <a href="./drivers"><strong>What\'s driving it →</strong><span>This month\'s price changes by category, and what trimming removes.</span></a>
  <a href="./agreement"><strong>Do the measures agree? →</strong><span>How far core, median and trimmed mean diverge, and when.</span></a>
  <a href="./robustness"><strong>Why trimmed means are robust →</strong><span>How every possible trim performs at tracking trend inflation.</span></a>
  <a href="./data"><strong>Data and methods →</strong><span>Download the series; definitions and sources.</span></a>
</div>

## About these measures

- **Trimmed-mean PCE** drops the categories with the most extreme price changes each month (the lightest 24%% and heaviest 31%% of spending) and averages the rest, following the Dallas Fed\'s definition.
- **Median PCE** is the price change in the middle of the spending-weighted distribution of categories, following the Cleveland Fed\'s approach.
- **The best-trims range.** The paper shows that many trims track trend inflation about equally well: their errors cannot be statistically distinguished from the best trim\'s. Reporting the range they span, rather than one trim, shows how precisely underlying inflation is pinned down.
- All four series are computed by the authors from BEA\'s detailed PCE price data and differ slightly from the official Federal Reserve series. [Methods →](./data)
',
  json, mon(last), f1(tr), p_level, p_dir, p_mom, p_head,
  hero, tile("Trimmed-mean PCE", "k-tm"), tile("Median PCE", "k-median"), tile("Core PCE", "k-core"), tile("Headline PCE", "k-headline"),
  n_trims))
