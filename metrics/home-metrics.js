// Home page: a small "Citation metrics" panel under the profile links,
// filled from metrics/metrics.json (written by metrics/update_metrics.R).
(function () {
  const links = document.querySelector(".about-entity .about-links");
  if (!links) return;
  const fmt = n => Number(n).toLocaleString("en-IN");
  const has = v => v !== null && v !== undefined && v !== "";
  function card(name, d, items) {
    const stats = items.filter(([, v]) => has(v))
      .map(([k, v]) => `<div class="hm-stat"><span class="hm-num">${fmt(v)}</span>${k}</div>`).join("");
    if (!stats) return "";
    return `<a class="hm-card" href="metrics.html"><div class="hm-src">${name}</div><div class="hm-stats">${stats}</div></a>`;
  }
  fetch("metrics/metrics.json", { cache: "no-cache" })
    .then(r => r.json())
    .then(d => {
      let html = "";
      if (d.scholar && has(d.scholar.citations))
        html += card("Google Scholar", d.scholar,
          [["Citations", d.scholar.citations], ["h-index", d.scholar.h_index], ["i10-index", d.scholar.i10_index]]);
      if (d.scopus)
        html += card("Scopus", d.scopus,
          [["Citations", d.scopus.citations], ["h-index", d.scopus.h_index], ["Documents", d.scopus.documents]]);
      if (!html) return;
      const dates = [d.scholar && has(d.scholar.citations) ? d.scholar.updated : null, d.scopus ? d.scopus.updated : null]
        .filter(Boolean).sort();
      const box = document.createElement("div");
      box.className = "home-metrics";
      box.innerHTML = `<div class="hm-title">Citation metrics</div>${html}` +
        `<div class="hm-foot">Updated ${dates[dates.length - 1]} · <a href="metrics.html">details</a></div>`;
      links.insertAdjacentElement("afterend", box);
    })
    .catch(() => {});
})();
