# Loads this repository's functions (R/functions/shared and
# R/functions/literature) into the global environment, the way the entry
# scripts do.
suppressPackageStartupMessages({
  library(httr2)     # attached by the entry scripts, used without httr2::
  library(jsonlite)
  library(purrr)
})
repo_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/")
for (f in list.files(file.path(repo_root, "R", "functions", c("shared", "literature")), pattern = "\\.R$", full.names = TRUE)) {
  sys.source(f, envir = globalenv())
}
# Config defaults and prompts come from this repository (read_config_yaml(),
# resolve_shared_path()), wherever a test runs.
options(bot.shared_root = repo_root)

# A workspace like a runner job's in `dir`: this repository in .hub. The
# entry scripts are then run from .hub/R.
local_hub_workspace <- function(dir) {
  dir.create(file.path(dir, ".hub"), showWarnings = FALSE)
  file.copy(file.path(repo_root, c("R", "config", "prompts")), file.path(dir, ".hub"), recursive = TRUE)
  invisible(dir)
}

# Replaces functions in the global environment (where helper-load.R put
# them) until the calling test ends.
local_global_mock <- function(..., env = parent.frame()) {
  mocks <- list(...)
  originals <- mget(names(mocks), envir = globalenv())
  for (n in names(mocks)) {
    assign(n, mocks[[n]], envir = globalenv())
  }
  withr::defer(for (n in names(originals)) {
    assign(n, originals[[n]], envir = globalenv())
  }, envir = env)
}
