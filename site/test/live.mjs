// Check the deployed site from the outside: a cold first visit to every page.
//   npm run test:live            (or: node test/live.mjs https://other.host/path/)
// Reports first paint, time to the first chart, bytes transferred, errors and hosts.
import puppeteer from "puppeteer-core";
const BASE = process.argv[2] ?? "https://dominic-smith.com/robust-inflation-dashboard/";
const CHROME = process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const browser = await puppeteer.launch({executablePath: CHROME, headless: true});
const hosts = new Set(); let bad = 0;
console.log("page                    first paint   first chart   transferred   errors");
for (const p of ["", "trend-range", "measures", "drivers", "agreement", "robustness", "data"]) {
  const ctx = await browser.createBrowserContext();          // fresh cache = first visit
  const page = await ctx.newPage(); await page.setViewport({width: 1280, height: 1000});
  const cdp = await page.createCDPSession(); await cdp.send("Network.enable");
  let bytes = 0; cdp.on("Network.loadingFinished", (e) => { bytes += e.encodedDataLength; });
  page.on("request", (r) => { const u = new URL(r.url()); if (u.protocol.startsWith("http")) hosts.add(u.host); });
  const errors = []; page.on("pageerror", (e) => errors.push(String(e)));
  const t0 = Date.now();
  await page.goto(BASE + p, {waitUntil: "domcontentloaded"});
  await page.waitForSelector(p === "data" ? "main table tbody tr" : "main svg g[aria-label]", {timeout: 30000});
  const chart = Date.now() - t0;
  await page.waitForNetworkIdle({idleTime: 300});
  const fcp = await page.evaluate(() => performance.getEntriesByName("first-contentful-paint")[0]?.startTime ?? NaN);
  const fw = await page.evaluate(() => document.querySelectorAll(".observablehq--error").length);
  bad += errors.length + fw;
  console.log(`${("/" + p).padEnd(22)}  ${String(Math.round(fcp)).padStart(6)} ms   ${String(chart).padStart(7)} ms   ${String(Math.round(bytes / 1024)).padStart(7)} KB   ${errors.length + fw}`);
  await ctx.close();
}
console.log("hosts contacted:", [...hosts].join(", "));
await browser.close();
process.exit(bad ? 1 : 0);
