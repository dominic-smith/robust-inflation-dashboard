// End-to-end check of the built site (site/dist). Run after `npm run build`:
//
//   npm test                 (CHROME_PATH=/path/to/chrome to override the browser)
//
// Serves dist/ locally, drives headless Chrome through every page, and fails if:
//  - any page throws or shows a Framework error
//  - any request leaves the site (no third-party hosts allowed)
//  - the Overview's key numbers are missing from the static HTML (before JavaScript)
//  - numbers shown on the pages differ from the validated artifacts. Expected values
//    are recomputed here, independently of the R loaders, from ../artifacts/*.csv.
// Writes full-page screenshots to test/shots/ (git-ignored) and prints load times.
import {createServer} from "node:http";
import {readFileSync, existsSync, mkdirSync, statSync} from "node:fs";
import {join, extname, dirname} from "node:path";
import {fileURLToPath} from "node:url";
import puppeteer from "puppeteer-core";

const here = dirname(fileURLToPath(import.meta.url));
const DIST = join(here, "../dist"), ART = join(here, "../../artifacts"), SHOTS = join(here, "shots");
mkdirSync(SHOTS, {recursive: true});
const CHROME = process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

// ---- tiny CSV reader (handles quoted fields) ----------------------------------
function readCSV(file) {
  const rows = [];
  for (const line of readFileSync(join(ART, file), "utf8").trim().split("\n")) {
    const out = []; let cur = "", q = false;
    for (const ch of line) {
      if (ch === '"') q = !q;
      else if (ch === "," && !q) { out.push(cur); cur = ""; }
      else cur += ch;
    }
    out.push(cur); rows.push(out);
  }
  const [head, ...body] = rows;
  return body.map((r) => Object.fromEntries(head.map((h, i) => [h, r[i]])));
}

// ---- expected values, from the artifacts -----------------------------------------
const series = readCSV("series_h.csv").map((r) => ({...r, value: +r.value}));
const band = readCSV("best_trims_band.csv").map((r) => ({...r, lo: +r.lo, hi: +r.hi, mean: +r.mean}));
const lastDate = series.filter((r) => r.horizon === "12m").map((r) => r.date).sort().at(-1);
const val = (m, h, d = lastDate) => series.find((r) => r.measure === m && r.horizon === h && r.date === d)?.value;
const bandLast = (t, s) => band.filter((r) => r.target === t && r.sample === s).sort((a, b) => (a.date < b.date ? -1 : 1)).at(-1);
const spread = (h) => { const v = ["Core PCE", "Median PCE", "Trimmed-mean PCE"].map((m) => val(m, h)); return Math.max(...v) - Math.min(...v); };
const f1 = (x) => (x < 0 ? "−" : "") + Math.abs(x).toFixed(1);

// ---- static server for dist/ (clean URLs like GitHub/Cloudflare Pages) -------------
const TYPES = {".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".csv": "text/csv", ".json": "application/json", ".svg": "image/svg+xml"};
const server = createServer((req, res) => {
  let p = decodeURIComponent(new URL(req.url, "http://x").pathname);
  let file = join(DIST, p);
  if (p.endsWith("/")) file = join(file, "index.html");
  else if (!existsSync(file) || statSync(file).isDirectory()) file += ".html";
  if (!existsSync(file)) { res.writeHead(404); return res.end("not found"); }
  res.writeHead(200, {"content-type": TYPES[extname(file)] ?? "application/octet-stream"});
  res.end(readFileSync(file));
}).listen(0, "127.0.0.1");
await new Promise((r) => server.once("listening", r));
const BASE = `http://127.0.0.1:${server.address().port}/`;

const failures = [];
const check = (ok, what) => { console.log(`${ok ? "  ok  " : " FAIL "} ${what}`); if (!ok) failures.push(what); };

// ---- 1. static HTML of the Overview (no JavaScript) --------------------------------
const bl = bandLast("c_0_37", "long");
const raw = await (await fetch(BASE)).text();
check(raw.includes(`running at about ${f1(bl.mean)}%`), `Overview static HTML states the best-trims average (${f1(bl.mean)}%)`);
check(raw.includes(`${f1(bl.lo)}–${f1(bl.hi)}%`), `Overview static HTML states the range (${f1(bl.lo)}–${f1(bl.hi)}%)`);
for (const m of ["Trimmed-mean PCE", "Median PCE", "Core PCE", "Headline PCE"])
  check(raw.includes(`${m}</div><div class="value">${f1(val(m, "12m"))}%`), `Overview static tile: ${m} ${f1(val(m, "12m"))}%`);

// ---- 2. every page, in the browser --------------------------------------------------
const browser = await puppeteer.launch({executablePath: CHROME, headless: true});
const pages = ["", "trend-range", "measures", "drivers", "agreement", "robustness", "data"];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function open(path) {
  const ctx = await browser.createBrowserContext();
  const page = await ctx.newPage(); await page.setViewport({width: 1280, height: 1000});
  const hosts = new Set(), errors = [];
  page.on("request", (r) => { const u = new URL(r.url()); if (u.protocol.startsWith("http")) hosts.add(u.host); });
  page.on("pageerror", (e) => errors.push(String(e).slice(0, 160)));
  const t0 = Date.now();
  await page.goto(BASE + path, {waitUntil: "networkidle0"});
  const ms = Date.now() - t0;
  await sleep(300);
  const fw = await page.evaluate(() => [...document.querySelectorAll(".observablehq--error")].map((e) => e.innerText.slice(0, 160)));
  return {page, ctx, ms, hosts, errors: [...errors, ...fw]};
}
const tiles = (page) => page.evaluate(() => Object.fromEntries([...document.querySelectorAll(".tile")].map((t) => [t.querySelector(".label").innerText.trim(), t.querySelector(".value").innerText.trim()])));
const choose = (page, label) => page.evaluate((l) => { const i = [...document.querySelectorAll("form.seg input[type=radio]")].find((x) => x.nextElementSibling?.innerText.trim() === l); i.click(); }, label);

for (const p of pages) {
  const {page, ctx, ms, hosts, errors} = await open(p);
  check(errors.length === 0, `/${p} renders without errors${errors.length ? ": " + errors.join(" | ") : ""} (${ms} ms to network idle)`);
  const foreign = [...hosts].filter((h) => h !== new URL(BASE).host);
  check(foreign.length === 0, `/${p} makes no third-party requests${foreign.length ? ": " + foreign.join(", ") : ""}`);

  if (p === "measures") {
    for (const [label, h] of [["12-month", "12m"], ["3-month", "3m"], ["1-month", "1m"]]) {
      await choose(page, label); await sleep(500);
      const t = await tiles(page);
      for (const m of ["Trimmed-mean PCE", "Median PCE", "Core PCE", "Headline PCE"])
        check(t[m] === `${f1(val(m, h))}%`, `/measures ${h} ${m}: shows ${t[m]}, expected ${f1(val(m, h))}%`);
    }
    await choose(page, "12-month"); await sleep(300);
  }
  if (p === "trend-range") {
    for (const [tl, t, sl, s] of [["Current trend", "c_0_37", "1970–2024", "long"], ["Future trend", "f_12_24", "2000–2024", "00s"], ["Band-pass trend", "b_2_39", "1970–1989", "80s"]]) {
      await choose(page, tl); await choose(page, sl); await sleep(600);
      const b = bandLast(t, s), v = await tiles(page);
      check(v["Range of the best trims"] === `${b.lo.toFixed(1)}–${b.hi.toFixed(1)}%`, `/trend-range ${t}/${s} range: ${v["Range of the best trims"]}`);
      check(v["Best-trims average"] === `${f1(b.mean)}%`, `/trend-range ${t}/${s} average: ${v["Best-trims average"]}`);
    }
    await choose(page, "Current trend"); await choose(page, "1970–2024"); await sleep(400);
  }
  if (p === "agreement") {
    const v = await tiles(page);
    check(v["Spread now"] === `${spread("12m").toFixed(1)} pp`, `/agreement spread now: ${v["Spread now"]}, expected ${spread("12m").toFixed(1)} pp`);
  }
  if (p === "robustness") {
    const before = await page.evaluate(() => performance.getEntriesByType("resource").map((r) => r.name).filter((n) => /heat\/[45]\./.test(n)).map((n) => n.split("/").pop().split(".")[0]));
    check(before.join() === "4", `/robustness loads only the all-categories heatmap at first (${before.join()})`);
    for (const v of ["Statistical tie with best", "Average bias"]) { await choose(page, v); await sleep(500); }
    const err = await page.evaluate(() => document.querySelectorAll(".observablehq--error").length);
    check(err === 0, "/robustness switches views without errors");
    // Colour direction: read the raster's pixels. In the bias view (light mode) the best
    // trim 17/19 has bias 0.03 pp and must be darker (stronger) than 20/30 at 0.38 pp.
    await page.emulateMediaFeatures([{name: "prefers-color-scheme", value: "light"}]); await sleep(600);
    const lum = await page.evaluate(async () => {
      let im = null;   // the 51x51 heatmap raster (not the 256x1 legend ramp)
      for (const el of document.querySelectorAll("main svg image")) {
        const x = new Image(); x.src = el.getAttribute("href"); await x.decode();
        if (x.width === 51 && x.height === 51) im = x;
      }
      if (!im) return {best: NaN, worse: NaN, size: "no 51x51 raster"};
      const cv = document.createElement("canvas"); cv.width = im.width; cv.height = im.height;
      const g = cv.getContext("2d"); g.drawImage(im, 0, 0);
      // Plot's raster image rows run with beta (row index = beta); require opaque pixels
      const at = (lb, beta) => { const [r, gr, b, a] = g.getImageData(lb, beta, 1, 1).data; return a === 255 ? 0.2126 * r + 0.7152 * gr + 0.0722 * b : NaN; };
      return {best: at(17, 19), worse: at(20, 30), size: [im.width, im.height]};
    });
    check(lum.best < lum.worse, `/robustness bias colours: best trim darker than a high-bias trim (luminance ${lum.best.toFixed(0)} < ${lum.worse.toFixed(0)}, raster ${lum.size})`);
    await page.emulateMediaFeatures([{name: "prefers-color-scheme", value: "no-preference"}]);
  }
  for (const mode of ["light", "dark"]) {   // charts re-colour on the scheme switch; screenshot both
    await page.emulateMediaFeatures([{name: "prefers-color-scheme", value: mode}]);
    await sleep(600);
    await page.screenshot({path: join(SHOTS, `${p || "index"}-${mode}.png`), fullPage: true});
  }
  const after = await page.evaluate(() => document.querySelectorAll(".observablehq--error").length);
  check(after === 0, `/${p} has no errors after switching light/dark`);
  await ctx.close();
}

// ---- 3. horizon choice carries across pages -----------------------------------------
{
  const ctx = await browser.createBrowserContext(); const page = await ctx.newPage();
  await page.goto(BASE + "measures", {waitUntil: "networkidle0"}); await choose(page, "3-month"); await sleep(300);
  await page.goto(BASE + "drivers", {waitUntil: "networkidle0"}); await sleep(300);
  const sel = await page.evaluate(() => [...document.querySelectorAll("form.seg input:checked")].map((i) => i.nextElementSibling.innerText.trim()));
  check(sel.includes("3-month"), `horizon choice carries from /measures to /drivers (${sel.join(", ")})`);
  await ctx.close();
}

await browser.close(); server.close();
console.log(failures.length ? `\n${failures.length} check(s) failed` : "\nall checks passed");
process.exit(failures.length ? 1 : 0);
