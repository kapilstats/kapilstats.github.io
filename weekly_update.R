# weekly_update.R
# Weekly update of the website kapilstats.github.io
#   1. installs the R packages it needs (first time only)
#   2. updates the Google Scholar and Scopus numbers (metrics/update_metrics.R)
#   3. rebuilds the website (quarto render)
#   4. shows what has changed and, if you answer y, publishes it (git push)
#
# How to run: open this file in RStudio and click "Source" (or press Ctrl+Shift+S).
# Run it in RStudio rather than with Rscript, because step 4 asks you a question.


# ---------------------------------------------------------------------------
# 0. Website foldery
# ---------------------------------------------------------------------------
setwd("D:/GitHub/kapilstats.github.io")


# ---------------------------------------------------------------------------
# 1. R packages (installed only if they are missing)
# ---------------------------------------------------------------------------
for (p in c("scholar", "jsonlite")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}
library(scholar)
library(jsonlite)

# Quarto and Git: found on the PATH, or else in their usual Windows folders
# (the last Quarto place is the copy that comes inside RStudio)
quarto <- Sys.which("quarto")
if (quarto == "") {
  places <- c(Sys.getenv("QUARTO_PATH"),
              "C:/Program Files/Quarto/bin/quarto.exe",
              file.path(Sys.getenv("LOCALAPPDATA"), "Programs/Quarto/bin/quarto.exe"),
              "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe")
  quarto <- places[places != "" & file.exists(places)][1]
}
if (is.na(quarto)) stop("Quarto was not found. In PowerShell run:  winget install --id Posit.Quarto  and then restart RStudio.")

git <- Sys.which("git")
if (git == "") {
  places <- c("C:/Program Files/Git/cmd/git.exe",
              file.path(Sys.getenv("LOCALAPPDATA"), "Programs/Git/cmd/git.exe"))
  git <- places[file.exists(places)][1]
}
if (is.na(git)) stop("Git was not found. In PowerShell run:  winget install --id Git.Git  and then restart RStudio.")

quarto <- paste0('"', quarto, '"')    # quotes, because the folder names can contain spaces
git    <- paste0('"', git, '"')
message("Using Quarto: ", quarto, "\nUsing Git:    ", git)


# ---------------------------------------------------------------------------
# 2. Update the citation numbers
# ---------------------------------------------------------------------------
# For new Scopus numbers, first save a fresh Scopus export as
# metrics/raw/scopus_export.csv (see the notes in metrics/update_metrics.R).
source("metrics/update_metrics.R")


# ---------------------------------------------------------------------------
# 3. Rebuild the website (this also sets the "Last updated on" date)
# ---------------------------------------------------------------------------
status <- system(paste(quarto, "render"))
if (status != 0) stop("quarto render did not finish. Nothing has been published.")


# ---------------------------------------------------------------------------
# 4. Publish
# ---------------------------------------------------------------------------
changes <- system(paste(git, "status --porcelain"), intern = TRUE)
files   <- substring(changes, 4)                   # file names without the status letters

if (length(changes) == 0) {
  message("Nothing new to publish.")
} else {
  other <- files[!startsWith(files, "docs/")]      # changes outside the built website
  message(sum(startsWith(files, "docs/")), " file(s) of the built website (docs/) have changed.")
  if (length(other) > 0) {
    message("Other changed files:")
    message(paste0("  ", other, collapse = "\n"))
  }

  answer <- readline("Publish these changes on kapilstats.github.io? (y/n): ")

  if (tolower(trimws(answer)) == "y") {
    system(paste(git, "add -A"))
    committed <- system(paste0(git, ' commit -q -m "Weekly update ', Sys.Date(), '"'))
    if (committed != 0) {
      message("git commit did not succeed (see the message above). Nothing has been published.")
    } else {
      pushed <- system(paste(git, "push"))
      if (pushed == 0) {
        message("Published. The website shows the changes within a few minutes.")
      } else {
        message("git push did not succeed (see the message above). The changes are saved on this laptop.")
      }
    }
  } else {
    message("Not published. The changes stay on this laptop.")
  }
}
