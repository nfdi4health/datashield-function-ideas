# Loads the hub's functions (R/functions/literature) and the shared ones
# from datashield-workflows (R/functions/shared: the Claude call, config
# merging) into the global environment, the way the entry scripts do.
# datashield-workflows comes from the folder in DATASHIELD_WORKFLOWS, else
# .shared-workflows in this repository (CI checks it out there), else a
# clone next to this one.
suppressPackageStartupMessages({
  library(httr2)     # attached by the entry scripts, used without httr2::
  library(jsonlite)
  library(purrr)
})
repo_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/")
workflows_root <- local({
  candidates <- c(Sys.getenv("DATASHIELD_WORKFLOWS"), file.path(repo_root, ".shared-workflows"),
    file.path(repo_root, "..", "datashield-workflows"))
  found <- candidates[nzchar(candidates) & dir.exists(file.path(candidates, "R", "functions", "shared"))]
  if (length(found) == 0) stop("datashield-workflows not found: set DATASHIELD_WORKFLOWS.", call. = FALSE)
  normalizePath(found[1], winslash = "/")
})
for (f in c(list.files(file.path(workflows_root, "R", "functions", "shared"), pattern = "\\.R$", full.names = TRUE),
  list.files(file.path(repo_root, "R", "functions", "literature"), pattern = "\\.R$", full.names = TRUE))) {
  sys.source(f, envir = globalenv())
}

# What the workflows see as the shared defaults: datashield-workflows'
# config/claude.yml with the hub's profiles merged over it, and the hub's
# other config files and prompts. read_config_yaml() reads its defaults
# from here (option bot.shared_root), wherever a test runs.
shared_defaults <- local({
  dir <- file.path(tempdir(), "hub-shared-defaults")
  unlink(dir, recursive = TRUE)
  dir.create(file.path(dir, "config"), recursive = TRUE)
  claude <- merge_config(yaml::read_yaml(file.path(workflows_root, "config", "claude.yml")),
    yaml::read_yaml(file.path(repo_root, "config", "claude.yml")))
  yaml::write_yaml(claude, file.path(dir, "config", "claude.yml"))
  for (f in setdiff(list.files(file.path(repo_root, "config"), pattern = "\\.yml$"), "claude.yml")) {
    file.copy(file.path(repo_root, "config", f), file.path(dir, "config", f))
  }
  file.copy(file.path(repo_root, "prompts"), dir, recursive = TRUE)
  dir
})
options(bot.shared_root = shared_defaults)

# A workspace like a runner job's in `dir`: the hub's R code in .hub, the
# shared functions and the defaults (config, prompts) in .shared-workflows.
# The entry scripts are then run from .hub/R.
local_hub_workspace <- function(dir) {
  dir.create(file.path(dir, ".hub"), showWarnings = FALSE)
  file.copy(file.path(repo_root, "R"), file.path(dir, ".hub"), recursive = TRUE)
  shared <- file.path(dir, ".shared-workflows")
  dir.create(file.path(shared, "R", "functions"), recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(workflows_root, "R", "functions", "shared"), file.path(shared, "R", "functions"), recursive = TRUE)
  file.copy(file.path(shared_defaults, c("config", "prompts")), shared, recursive = TRUE)
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
