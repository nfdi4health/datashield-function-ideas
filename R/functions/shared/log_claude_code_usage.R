# Copied from nfdi4health/datashield-workflows (R/functions/shared/) on
# 2026-11-19; the hub keeps its own copy (fixes there may be needed here).
# Logs what a Claude Code call used, like datashield-workflows' log_claude_usage() does for the
# API: turns and tokens (on a subscription the cost isn't billed per call;
# Claude Code's estimate is shown when it gives one).
log_claude_code_usage <- function(result, label) {
  u <- result$usage %||% list()
  message(sprintf("Claude Code usage (%s): %s turn(s), input %s, cache read %s, output %s tokens%s", label,
    result$num_turns %||% "?", u$input_tokens %||% "?", u$cache_read_input_tokens %||% 0, u$output_tokens %||% "?",
    if (!is.null(result$total_cost_usd)) sprintf(", about %.2f USD if it were billed", result$total_cost_usd) else ""))
}
