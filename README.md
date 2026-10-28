# kapilstats.github.io

Source files for the personal academic website of Kapil Kumar, built with [Quarto](https://quarto.org) and published with GitHub Pages at **https://kapilstats.github.io**.

## Files

| File | What it is |
|------|------------|
| `_quarto.yml` | Site settings: title, menu, footer, theme |
| `index.qmd` | Home page (photo, bio, education, links) |
| `research.qmd` | Research themes with selected papers |
| `publications.qmd` + `publications.bib` | Publications page, built automatically from the `.bib` file |
| `metrics.qmd` + `metrics/` | Metrics page (Google Scholar and Scopus). `metrics/update_metrics.R` writes `metrics/metrics.json`; `metrics/metrics-console.js` draws the page |
| `teaching.qmd` | Teaching page: current courses (cards linking to the course pages) and courses taught |
| `teaching/<course>/` | One folder per current course: `index.qmd` (the course page) and the 60 lecture decks `Lecture_01.pdf` … `Lecture_60.pdf`, e.g. `teaching/econometrics/`. Nothing else is published: other PDFs in these folders are ignored by Git and by Quarto |
| `students.qmd` | PhD and MSc students |
| `talks.qmd` | Invited talks at conferences, sessions chaired, presentations (invited R lectures are on the Workshops page) |
| `workshops.qmd` + `workshops.yml` + `workshops.ejs` | Workshops page: one card per workshop/FDP, built from `workshops.yml` with the card layout in `workshops.ejs` |
| `workshops/` | Slides (PDF) for each workshop, one folder per workshop. R code and data are not published; they are shared by email on request |
| `gallery.qmd` | Photo gallery; photos go in `images/gallery/` |
| `cv.qmd` | CV page on the website, with a button to download the PDF |
| `cv/Kapil_Kumar_CV.tex` + `cv/kapil.jpg` | Full CV in LaTeX (moderncv); compile with pdfLaTeX, e.g. on Overleaf |
| `files/Kapil_Kumar_CV.pdf` | The compiled CV that visitors download |
| `new-tab-links.html` | Makes links to other websites and PDFs open in a new tab |
| `custom.scss` | Colours and small style changes |
| `images/` | Photo (`kapil.jpg`), site icon, gallery photos |
| `publications.lua`, `protect-titles.ts`, `newest-first.csl` | Helpers for the publication list (no need to edit) |
| `last-updated.ts` → `_variables.yml` | Writes today's date at every render; the footer shows it as "Last updated on …" (no need to edit) |
| `weekly_update.R` | **Run weekly in RStudio (Source):** updates the metrics, rebuilds the site, shows what changed and publishes it after you answer y |
| `scholargauge/` | Pages of the ScholarGauge Chrome extension (homepage, privacy policy, methods). Plain HTML, copied as they are into `docs/scholargauge/` by Quarto because the folder is listed under `resources:` in `_quarto.yml`. The originals live in `KStats_Lab_Apps\04_ScholarGauge\store\website\scholargauge` |
| `docs/` | The finished website (created by `quarto render`; do not edit by hand) |

## Updating the site (Windows PowerShell)

```powershell
cd D:\GitHub\kapilstats.github.io
quarto preview          # look at it in the browser while editing (Ctrl+C to stop)
quarto render           # build the final site into docs/
git add .
git commit -m "Update website"
git push
```

The live site updates a minute or two after `git push`.

## Common tasks

- **New paper:** open `publications.bib`, copy an existing entry, give it a new key and edit the fields. Do not replace the file with a fresh Google Scholar export, because that would lose the corrections and DOIs.
- **Order of publications:** newest first by default. To list oldest first (numbered 1, 2, 3, ...), change `local newest_first = true` to `false` near the top of `publications.lua`.
- **CV:** edit `cv/Kapil_Kumar_CV.tex` (for example in Overleaf, uploading the `cv` folder), compile it, and save the PDF as `files/Kapil_Kumar_CV.pdf`. Then render and push.
- **Gallery photos:** follow the instructions at the top of `gallery.qmd`.
- **Course slides:** only the lecture decks are published. To update one, replace its `Lecture_nn.pdf` in `teaching/<course>/` (keep the file name) and correct its slide count in that folder's `index.qmd` if it changed. For a new course, copy a course folder, edit its `index.qmd`, and add a card for it in `teaching.qmd`.
- **Citation metrics (weekly):** open `weekly_update.R` in RStudio and click *Source*. It updates the numbers, rebuilds the site, lists what changed and publishes after you answer `y`. Google Scholar is read automatically; if it refuses the request, the old numbers are kept. For new Scopus numbers, first save a fresh Scopus CSV export as `metrics/raw/scopus_export.csv` (this folder is not published).
- **New workshop lecture:** make a folder `workshops/<yyyy-mm-short-name>/` with the slide PDF(s), then copy an entry in `workshops.yml` and edit it. The page sorts by date and updates the topic filter by itself.
- **Custom domain later:** create a file named `CNAME` (no extension) next to `_quarto.yml` containing only the domain, e.g. `kapilstats.in`, add `- CNAME` under `resources:` in `_quarto.yml`, then render and push.
