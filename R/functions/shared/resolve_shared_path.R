# Copied from nfdi4health/datashield-workflows (R/functions/shared/) on
# 2026-11-19; the hub keeps its own copy (fixes there may be needed here).
# Resolves a path given relative to this repository's root (e.g.
# "prompts/methods-exists-prompt.md"): the file in the working directory
# if it exists (the workspace root, i.e. main, in the runner; this
# repository when run locally), otherwise the copy in .hub (option
# `bot.shared_root` in the tests). For prompt templates, which are replaced
# as a whole; config files are merged instead (read_config_yaml()).
resolve_shared_path <- function(rel_path) {
  if (file.exists(rel_path)) {
    rel_path
  } else {
    file.path(getOption("bot.shared_root", ".hub"), rel_path)
  }
}
