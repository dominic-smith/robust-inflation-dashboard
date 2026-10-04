// Lightweight inputs that work with Framework's view() / Generators.input(): each
// returns a <form> with a .value and fires "input" events. They replace
// @observablehq/inputs, which saves its JS and CSS on every page.
import {html} from "../../_npm/htl@1.0.0/11521f02.js";

let uid = 0;

// Segmented control (radio group styled as pills).
// options: Map(label -> value) or array of values. key: persist the choice for the
// session under this sessionStorage key (used for the horizon shared across pages).
export function segmented(options, {label, value, key} = {}) {
  const entries = options instanceof Map ? [...options] : options.map((o) => [String(o), o]);
  let initial = value ?? entries[0][1];
  if (key) {
    try {
      const saved = sessionStorage.getItem(key);
      const hit = entries.find(([, v]) => String(v) === saved);
      if (hit) initial = hit[1];
    } catch {}
  }
  const name = `seg${++uid}`;
  const form = html`<form class="seg">
    ${label ? html`<span class="seg-label" id=${`${name}-label`}>${label}</span>` : null}
    <div class="seg-opts" role="radiogroup" aria-labelledby=${label ? `${name}-label` : null}>
      ${entries.map(([text, v]) => html`<label class="seg-opt"><input type="radio" name=${name} value=${String(v)} checked=${v === initial}><span>${text}</span></label>`)}
    </div>
  </form>`;
  form.value = initial;
  // Registered before Framework's listener, so .value is current when it reads it.
  form.addEventListener("input", (event) => {
    const hit = entries.find(([, v]) => String(v) === event.target.value);
    if (!hit) return;
    form.value = hit[1];
    if (key) try { sessionStorage.setItem(key, String(hit[1])); } catch {}
  });
  form.addEventListener("submit", (event) => event.preventDefault());
  return form;
}

// Checkbox group with a colour key per option. value: initially checked options.
// keyClass(option) names a CSS class that sets --k, so keys follow light/dark mode
// without rebuilding the control (which would reset the selection).
export function checkboxes(options, {label, value = options, keyClass} = {}) {
  const form = html`<form class="seg">
    ${label ? html`<span class="seg-label">${label}</span>` : null}
    <div class="checks">${options.map((o) => html`<label><input type="checkbox" value=${o} checked=${value.includes(o)}>
      ${keyClass ? html`<span class=${`key ${keyClass(o)}`}></span>` : null}${o}</label>`)}</div>
  </form>`;
  const read = () => [...form.querySelectorAll("input:checked")].map((i) => i.value);
  form.value = read();
  form.addEventListener("input", () => { form.value = read(); });
  form.addEventListener("submit", (event) => event.preventDefault());
  return form;
}
