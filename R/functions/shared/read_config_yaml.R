# Copied from nfdi4health/datashield-workflows (R/functions/shared/) on
# 2026-11-19; the hub keeps its own copy (fixes there may be needed here).
# Reads a YAML config (e.g. config/roxygen-style.yml) as the shared
# defaults with the project's own file at the same path merged over them,
# key by key (merge_config(): mappings merge, values and lists, also
# lists of mappings, are replaced as a whole). In the runner the defaults
# are .hub (this repository at the commit the workflow runs) and the
# file at the same path in the workspace root (main) is merged over them;
# the tests point the defaults elsewhere with option `bot.shared_root`.
# Outside the runner (no .hub/) the file is read as it is. A missing config
# stops the run, unless `required` is FALSE: then NULL.
read_config_yaml <- function(rel_path, required = TRUE) {
  shared <- file.path(getOption("bot.shared_root", ".hub"), rel_path)
  defaults <- if (file.exists(shared)) {
    yaml::read_yaml(shared)
  } else {
    list()
  }
  own <- if (file.exists(rel_path)) {
    yaml::read_yaml(rel_path)
  } else {
    list()
  }
  if (length(defaults) == 0 && length(own) == 0) {
    if (!required) {
      return(NULL)
    }
    stop(sprintf("Config not found: %s", rel_path), call. = FALSE)
  }
  # An empty YAML file reads as NULL.
  merged <- if (length(own) == 0) defaults %||% list() else merge_config(defaults %||% list(), own)
  record_provenance("config", rel_path, short_hash(merged))
  merged
}
