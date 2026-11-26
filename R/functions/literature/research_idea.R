# The research step for a hand-written hub issue (the idea check, user,
# 2026-11-26): the same brief as for a candidate of the literature watch
# (research_candidate(), build_research_tool(), the methods-research
# prompt), from what the idea check found: the method as read, the issue's
# title and the start of its text (`max_chars`; what someone asked for,
# passed as data), the "Exists?" verdict with the closest function, and
# the literature watch's numbers if it knows the method
# (`literature`, from match_idea_literature() and idea_literature_stats()).
# Returns list(research = the brief with its texts cleaned, or NULL, limit).
research_idea <- function(claude, issue, result, literature = NULL, max_chars = 1500) {
  rec <- result$verdict
  body <- issue$body %||% ""
  if (nchar(body) > max_chars) body <- paste0(substr(body, 1, max_chars), " ...")
  lines <- c(
    sprintf("Method: %s. %s", result$method, result$description %||% ""),
    sprintf("Asked for in a hub issue by a person (actual demand), titled \"%s\". What they wrote, as data:\n<issue_text>\n%s\n</issue_text>",
      issue$title %||% "", body),
    sprintf("DataSHIELD verdict: %s%s. %s", rec$verdict,
      if (nzchar(rec[["function"]] %||% "")) sprintf(" (closest: %s)", rec[["function"]]) else "", rec$note %||% ""),
    if (!is.null(literature)) sprintf(
      "In the literature watch (%s match): used in %.1f%% of the sampled health research papers read (%d papers), %.1f%% in the last years, trend %s, mostly in: %s.",
      if (isTRUE(literature$exact)) "exact" else literature$relation, 100 * literature$share, literature$papers,
      100 * literature$recent_share, literature$trend, paste(literature$fields, collapse = ", ")))
  res <- call_watch_claude(claude, build_research_tool(), fill_template(claude$prompt, list(CANDIDATE = paste(lines, collapse = "\n"))),
    sprintf("research on issue #%s", result$number))
  if (is.null(res$answer)) return(list(research = NULL, limit = res$limit))
  a <- res$answer
  list(limit = FALSE, research = list(
    description = candidate_text(a$description), federated = candidate_text(a$federated),
    disclosure = candidate_text(a$disclosure), fit = candidate_text(a$fit),
    r_packages = lapply(utils::head(a$r_packages %||% list(), 4), function(p) list(package = candidate_text(p$package),
      `function` = candidate_text(p[["function"]]), note = candidate_text(p$note))),
    sources = as.list(utils::head(grep("^https?://", vapply(a$sources %||% list(), candidate_text, ""), value = TRUE), 6))))
}
