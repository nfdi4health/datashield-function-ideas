# Copied from nfdi4health/datashield-workflows (R/functions/shared/) on
# 2026-11-19; the hub keeps its own copy (fixes there may be needed here).
# Everything a Claude call of one kind needs, passed explicitly instead of
# read from global variables: the `anthropic` settings of a profile of
# config/claude.yml (model, tool name, thinking, effort, …) and the prompt
# template (optional; resolve_shared_path()). Used by call_claude_tool().
claude_client <- function(profile, prompt_file = NULL) {
  prompt <- NULL
  if (!is.null(prompt_file)) {
    prompt <- read_text_file(prompt_file)
  }
  config <- claude_settings(profile)$anthropic
  record_provenance("model", profile, config$model %||% "")
  list(
    config = config,
    prompt = prompt
  )
}
