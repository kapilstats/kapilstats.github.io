// Metrics page: reads metrics/metrics.json (written by metrics/update_metrics.R)
// and draws the summary tiles, a bar chart and a searchable, sortable table.
// Plain JavaScript, no external libraries.
(function () {
  const body = document.getElementById("mc-body");
  if (!body) return;
  const tabs = Array.from(document.querySelectorAll(".mc-tab"));
  let data = null, source = "scholar", sortKey = "cites", sortDir = -1, query = "", showAll = false;
  const SHOW = 15;

  const esc = s => String(s == null ? "" : s).replace(/[&<>"']/g,
    c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const fmt = n => (n == null || n === "" || isNaN(n)) ? "–" : Number(n).toLocaleString("en-IN");

  function tiles(d) {
    const t = source === "scholar"
      ? [["Citations", d.citations], ["h-index", d.h_index], ["i10-index", d.i10_index], ["Documents", d.documents]]
      : [["Citations", d.citations], ["h-index", d.h_index], ["Documents", d.documents]];
    return '<div class="mc-tiles">' + t.map(([k, v]) =>
      `<div class="mc-tile"><span class="mc-num">${fmt(v)}</span>${k}</div>`).join("") + "</div>";
  }

  function chart(d) {
    const given = (d.by_year || []).filter(r => r.year != null);
    if (!given.length) return "";
    const years = given.map(r => Number(r.year)), rows = [];
    for (let y = Math.min(...years); y <= Math.max(...years); y++) {   // show empty years as 0
      const r = given.find(g => Number(g.year) === y);
      rows.push({ year: y, value: r ? r.value : 0 });
    }
    const W = 760, H = 230, L = 42, B = 26, T = 18, R = 8;
    const max = Math.max(...rows.map(r => r.value || 0), 1);
    const step = (W - L - R) / rows.length, bw = Math.max(4, step * 0.66);
    const nice = Math.pow(10, Math.floor(Math.log10(max))) / 10;
    const tick = [1, 2, 5, 10, 20, 50].map(m => Math.max(1, m * nice)).find(s => max / s <= 6) || max;
    let g = "";
    for (let v = 0; v <= max; v += tick) {
      const y = H - B - (v / max) * (H - B - T);
      g += `<line x1="${L}" x2="${W - R}" y1="${y}" y2="${y}" class="mc-grid"/>` +
           `<text x="${L - 6}" y="${y + 4}" class="mc-ax" text-anchor="end">${v}</text>`;
    }
    rows.forEach((r, i) => {
      const h = ((r.value || 0) / max) * (H - B - T), x = L + i * step + (step - bw) / 2, y = H - B - h;
      g += `<rect x="${x}" y="${y}" width="${bw}" height="${h}" rx="2" class="mc-bar"><title>${r.year}: ${r.value}</title></rect>`;
      if (rows.length <= 16 || i % 2 === 0)
        g += `<text x="${x + bw / 2}" y="${H - B + 15}" class="mc-ax" text-anchor="middle">${r.year}</text>`;
      if (rows.length <= 20)
        g += `<text x="${x + bw / 2}" y="${y - 4}" class="mc-val" text-anchor="middle">${r.value}</text>`;
    });
    const title = source === "scholar" ? "Citations received per year" : "Documents per year";
    return `<h3 class="mc-h">${title}</h3><svg viewBox="0 0 ${W} ${H}" class="mc-chart" role="img" aria-label="${title}">${g}</svg>`;
  }

  function table(d) {
    let rows = (d.papers || []).slice();
    const hasCites = rows.some(r => r.cites != null);
    const key = (sortKey === "cites" && !hasCites) ? "year" : sortKey;
    if (query) {
      const q = query.toLowerCase();
      rows = rows.filter(r => (r.title + " " + (r.source || "") + " " + (r.year || "")).toLowerCase().includes(q));
    }
    rows.sort((a, b) => {
      const x = a[key], y = b[key];
      if (x == null) return 1; if (y == null) return -1;
      return (typeof x === "number" ? x - y : String(x).localeCompare(String(y))) * sortDir;
    });
    const head = [["title", "Title", ""], ["year", "Year", ""], ["source", "Source", "mc-s"], ["cites", "Citations", ""]]
      .map(([k, l, c]) => `<th data-k="${k}" class="${(c + " " + (k === key ? (sortDir < 0 ? "desc" : "asc") : "")).trim()}">${l}</th>`).join("");
    const total = rows.length;
    if (!showAll && !query) rows = rows.slice(0, SHOW);
    // on phones the Source column is hidden and the source is shown under the title instead
    const trs = rows.map(r => `<tr><td>${r.link ? `<a href="${esc(r.link)}">${esc(r.title)}</a>` : esc(r.title)}` +
      `<span class="mc-s-inline">${esc(r.source)}</span></td>` +
      `<td>${esc(r.year)}</td><td class="mc-s">${esc(r.source)}</td><td class="mc-c">${fmt(r.cites)}</td></tr>`).join("");
    return `<h3 class="mc-h">Documents</h3>
      <input type="search" class="form-control mc-search" placeholder="Search title, source or year" value="${esc(query)}">
      <p class="mc-count">${rows.length} of ${(d.papers || []).length} documents · click a column heading to sort</p>
      <div class="mc-tablewrap"><table class="mc-table"><thead><tr>${head}</tr></thead><tbody>${trs}</tbody></table></div>` +
      (!query && total > SHOW ? `<button class="mc-more">${showAll ? "Show fewer" : "Show all " + total + " documents"}</button>` : "");
  }

  function render() {
    tabs.forEach(t => t.classList.toggle("active", t.dataset.source === source));
    const d = data && data[source];
    if (!d) {
      body.innerHTML = '<p class="mc-empty">No ' + (source === "scholar" ? "Google Scholar" : "Scopus") +
        " data yet. Run <code>metrics/update_metrics.R</code>, then render the site.</p>";
      return;
    }
    const name = source === "scholar" ? "Google Scholar" : "Scopus";
    const pending = d.citations == null
      ? '<p class="mc-empty">Citation counts appear after the next online update (<code>metrics/update_metrics.R</code>). The list below is from the exported profile.</p>' : "";
    body.innerHTML = tiles(d) + pending + chart(d) + table(d) +
      `<p class="mc-updated">Updated ${esc(d.updated)} · <a href="${esc(d.profile)}">${name} profile</a></p>`;
    const s = body.querySelector(".mc-search");
    s.addEventListener("input", e => { query = e.target.value; const pos = e.target.selectionStart; render();
      const n = body.querySelector(".mc-search"); n.focus(); n.setSelectionRange(pos, pos); });
    const more = body.querySelector(".mc-more");
    if (more) more.addEventListener("click", () => { showAll = !showAll; render(); });
    body.querySelectorAll("th").forEach(th => th.addEventListener("click", () => {
      const k = th.dataset.k;
      if (k === sortKey) sortDir = -sortDir; else { sortKey = k; sortDir = (k === "cites" || k === "year") ? -1 : 1; }
      render();
    }));
    body.querySelectorAll("a[href^='http']").forEach(a => { a.target = "_blank"; a.rel = "noopener"; });
  }

  tabs.forEach(t => {
    t.setAttribute("role", "button"); t.setAttribute("tabindex", "0");
    t.addEventListener("click", () => { source = t.dataset.source; query = ""; showAll = false; render(); });
    t.addEventListener("keydown", e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); t.click(); } });
  });

  fetch("metrics/metrics.json", { cache: "no-cache" })
    .then(r => r.json())
    .then(j => { data = j;
      // open on Scopus while Google Scholar has no citation numbers yet
      if ((!data.scholar || data.scholar.citations == null) && data.scopus) source = "scopus";
      render(); })
    .catch(() => { body.innerHTML = '<p class="mc-empty">The metrics file could not be loaded.</p>'; });
})();
