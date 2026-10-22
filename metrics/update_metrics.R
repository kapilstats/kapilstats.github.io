# update_metrics.R
# Updates the numbers shown on the Metrics page of kapilstats.github.io.
#
# Easiest: run weekly_update.R in the website folder. It installs the packages,
# runs this file, rebuilds the website and publishes it.
# This file alone only writes metrics/metrics.json; after it, run `quarto render`,
# commit and push.
#
# Part 1  Google Scholar: read directly from the public profile (package 'scholar').
#         If Google Scholar refuses the request, the list of documents is taken from
#         Scholar's own export (My profile > select all > Export > CSV) saved as
#         metrics/raw/scholar_export.csv. That export has no citation counts, so the
#         citation numbers then stay as they were.
# Part 2  Scopus: read from a CSV file exported from Scopus (no login needed by R).
#         In Scopus, open the author profile, select all documents, Export > CSV,
#         tick "Citation information" and "Bibliographical information", and save the
#         file as  metrics/raw/scopus_export.csv
# The raw/ folder is not published (see .gitignore).

# install once:
# install.packages(c("scholar", "jsonlite"))
library(scholar)
library(jsonlite)

scholar_id <- "5_ONzJUAAAAJ"          # from the Google Scholar profile link
scopus_id  <- "56087498200"           # from the Scopus author profile link
json_file  <- "metrics/metrics.json"
scopus_csv <- "metrics/raw/scopus_export.csv"
scholar_csv <- "metrics/raw/scholar_export.csv"

# start from the numbers already on the site
old <- list(scholar = NULL, scopus = NULL)
if (file.exists(json_file)) old <- fromJSON(json_file, simplifyVector = FALSE)
out <- old


# ---------------------------------------------------------------------------
# Part 1: Google Scholar
# ---------------------------------------------------------------------------
# Google Scholar sometimes refuses automated requests for a few hours (reply code 429,
# or an "unusual traffic" page). The scholar functions then give NA instead of a table,
# so the result is checked, and the warnings of the scholar package are kept to report.
scholar_warnings <- character(0)
gs <- tryCatch(withCallingHandlers({
  profile <- get_profile(scholar_id)
  history <- get_citation_history(scholar_id)          # citations received each year
  papers  <- get_publications(scholar_id)              # one row per paper
  if (!is.list(profile) || !is.data.frame(history) || !is.data.frame(papers) || nrow(papers) == 0)
    stop("Google Scholar did not send the profile page")
  # Google Scholar's web page drops the formula P(V < U) from this title; put it back
  papers$title <- sub("On Estimation of\\s+for Inverse Pareto", "On Estimation of P(V < U) for Inverse Pareto",
                      papers$title)
  papers  <- papers[order(-papers$cites, tolower(papers$title), method = "radix"), ]   # same order on every computer
  list(
    updated   = format(Sys.Date()),
    profile   = paste0("https://scholar.google.com/citations?user=", scholar_id),
    citations = profile$total_cites,
    h_index   = profile$h_index,
    i10_index = profile$i10_index,
    documents = nrow(papers),
    by_year   = data.frame(year = history$year, value = history$cites),
    papers    = data.frame(
      title  = papers$title,
      year   = papers$year,
      source = papers$journal,
      cites  = papers$cites,
      link   = paste0("https://scholar.google.com/citations?view_op=view_citation",
                      "&user=", scholar_id, "&citation_for_view=", scholar_id, ":", papers$pubid)
    )
  )
}, warning = function(w) {
  scholar_warnings <<- c(scholar_warnings, conditionMessage(w))
  invokeRestart("muffleWarning")
}), error = function(e) {
  reason <- conditionMessage(e)
  if (length(scholar_warnings) > 0) reason <- paste0(reason, "; ", paste(unique(scholar_warnings), collapse = "; "))
  message("Google Scholar could not be read (", reason, ").")
  message("  Google Scholar sometimes blocks automated requests for a few hours. The website keeps the\n",
          "  previous Google Scholar numbers; run weekly_update.R again later (or tomorrow) to update them.")
  NULL
})
if (!is.null(gs)) {
  out$scholar <- gs
  message("Google Scholar: ", gs$citations, " citations, h-index ", gs$h_index,
          ", i10-index ", gs$i10_index, ", ", gs$documents, " documents.")
} else if (file.exists(scholar_csv) && (is.null(out$scholar) || is.null(out$scholar$citations))) {
  # no online numbers yet: list the documents from the export (titles, years, sources; no citations)
  ex <- read.csv(scholar_csv, encoding = "UTF-8", check.names = FALSE,
                 stringsAsFactors = FALSE)
  names(ex) <- trimws(sub("^\ufeff", "", names(ex)))   # drop the byte-order mark
  ex$Title <- gsub("$P (V< U)$", "P(V < U)", ex$Title, fixed = TRUE)   # LaTeX in one title
  ex <- ex[order(-ex$Year, tolower(ex$Title), method = "radix"), ]
  old_gs <- out$scholar
  out$scholar <- list(
    updated   = format(as.Date(file.info(scholar_csv)$mtime)),
    profile   = paste0("https://scholar.google.com/citations?user=", scholar_id),
    citations = if (is.null(old_gs)) NULL else old_gs$citations,
    h_index   = if (is.null(old_gs)) NULL else old_gs$h_index,
    i10_index = if (is.null(old_gs)) NULL else old_gs$i10_index,
    documents = nrow(ex),
    by_year   = if (is.null(old_gs)) NULL else old_gs$by_year,
    papers    = data.frame(title = ex$Title, year = ex$Year, source = ex$Publication,
                           link = "")
  )
  message("Google Scholar: documents taken from ", scholar_csv, " (", nrow(ex),
          " documents; no citation counts in that file).")
}


# ---------------------------------------------------------------------------
# Part 2: Scopus (from the exported CSV file)
# ---------------------------------------------------------------------------
if (file.exists(scopus_csv)) {
  sc <- read.csv(scopus_csv, encoding = "UTF-8", check.names = FALSE,
                 stringsAsFactors = FALSE)
  names(sc) <- trimws(sub("^\ufeff", "", names(sc)))   # drop the byte-order mark
  needed <- c("Title", "Year", "Source title", "Cited by")
  missing_cols <- setdiff(needed, names(sc))
  if (length(missing_cols) > 0) {
    stop("The Scopus file has no column(s): ", paste(missing_cols, collapse = ", "),
         ". Export again with 'Citation information' ticked.")
  }

  cites <- sc[["Cited by"]]
  cites[is.na(cites)] <- 0                    # Scopus leaves the cell empty when there are no citations
  cites_sorted <- sort(cites, decreasing = TRUE)
  h <- sum(cites_sorted >= seq_along(cites_sorted))   # h-index: h papers with at least h citations each

  docs_per_year <- table(sc$Year)
  link <- ""
  if ("DOI" %in% names(sc)) {
    link <- ifelse(!is.na(sc$DOI) & sc$DOI != "", paste0("https://doi.org/", sc$DOI), "")
  }

  papers_sc <- data.frame(title = sc$Title, year = sc$Year, source = sc[["Source title"]],
                          cites = cites, link = link)
  papers_sc <- papers_sc[order(-papers_sc$cites, tolower(papers_sc$title), method = "radix"), ]

  out$scopus <- list(
    updated   = format(as.Date(file.info(scopus_csv)$mtime)),
    profile   = paste0("https://www.scopus.com/authid/detail.uri?authorId=", scopus_id),
    citations = sum(cites),
    h_index   = h,
    documents = nrow(sc),
    by_year   = data.frame(year = as.integer(names(docs_per_year)), value = as.integer(docs_per_year)),
    papers    = papers_sc
  )
  message("Scopus: ", nrow(sc), " documents, ", sum(cites), " citations, h-index ", h, ".")
} else {
  message("No Scopus file at ", scopus_csv, ". Keeping the old Scopus numbers.")
}


# ---------------------------------------------------------------------------
# Save for the website
# ---------------------------------------------------------------------------
write_json(out, json_file, auto_unbox = TRUE, pretty = TRUE, dataframe = "rows", null = "null")
message("Saved ", json_file, ".")
