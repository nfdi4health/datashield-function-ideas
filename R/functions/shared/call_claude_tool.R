# The hub's Claude call: Claude answers through the given tool, and its
# parsed input is returned. Only the subscription path: every call goes
# through Claude Code with CLAUDE_CODE_OAUTH_TOKEN (call_claude_code_tool()),
# the way the runner runs the hub's workflows. The tool's name is set here
# from config$tool_name; the schema is sent strict (strict_tool_schema())
# unless a profile sets `strict: false`.
#
# Copied from nfdi4health/datashield-workflows (R/functions/shared/) on
# 2026-11-19 and trimmed: the Messages API path (WIF, token renewal) is
# left out. Fixes there may be needed here too, and the other way round.
call_claude_tool <- function(claude, tool, prompt) {
  config <- claude$config
  tool$name <- config$tool_name
  if (!nzchar(Sys.getenv("CLAUDE_CODE_OAUTH_TOKEN"))) {
    stop("No CLAUDE_CODE_OAUTH_TOKEN: the hub calls Claude only through a subscription.", call. = FALSE)
  }
  if (!isFALSE(config$strict)) {
    strict <- strict_tool_schema(tool$input_schema)
    if (strict$ok) tool$input_schema <- strict$schema
  }
  call_claude_code_tool(claude, tool, prompt)
}
