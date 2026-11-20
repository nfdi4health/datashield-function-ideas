# The candidate pull request's description: what to do, the new
# candidates in two lists (`new$list`: "most-used", by share over all
# years read, then "rising", a rising trend; format_candidate_section()),
# the deferred ones with their own boxes, and those already tracked by a
# hub issue (no boxes). `coverage`: papers read per publication year
# (coverage_by_year()), on top; `researched_on`: each brief's date, by key.
format_candidates_body <- function(new, deferred, tracked_rows, tracked, vocab, research, month,
                                   coverage = NULL, researched_on = list()) {
  label <- function(row) {
    name <- method_label(vocab, row$method)
    if (nzchar(row$variant)) sprintf("%s: %s", name, method_label(vocab, row$method, row$variant)) else name
  }
  out <- c(sprintf("The literature watch's candidates for %s: methods health research uses often that DataSHIELD lacks.", month), "",
    if (!is.null(coverage)) c(format_coverage(coverage), ""),
    "Tick **exactly one** box per candidate (the check stays red until every candidate has one), then merge:",
    "- **Open an issue**: an idea issue is opened here, with this brief.",
    "- **Not now**: listed again next month under \"Deferred\".",
    "- **Don't suggest again**: left out until its papers double.", "",
    "The research is Claude's, with web search: a starting point, not a verdict. A brief is kept for six months and updated after that, or earlier when the DataSHIELD verdict changes.", "")
  lists <- list(`most-used` = c("## Most used", "", "The methods used most in the papers read, over all years, that DataSHIELD lacks.", ""),
    rising = c("## On the rise", "", "Methods whose share grows clearly from year to year (p < 0.05), by their share in the last years; not in the list above.", ""))
  i <- 0
  for (l in names(lists)) {
    rows <- which((new$list %||% rep("most-used", nrow(new))) == l)
    if (length(rows) == 0) next
    out <- c(out, lists[[l]])
    for (r in rows) {
      i <- i + 1
      out <- c(out, format_candidate_section(i, new[r, ], vocab, research[[new$key[r]]], researched_on[[new$key[r]]]))
    }
  }
  if (nrow(deferred) > 0) {
    out <- c(out, "## Deferred", "")
    for (i in seq_len(nrow(deferred))) {
      row <- deferred[i, ]
      out <- c(out, sprintf("**%s**: %.1f%% of papers (%d), trend %s.", label(row), 100 * row$share, row$papers, row$trend), "",
        candidate_boxes(row$key), "")
      if (!is.null(research[[row$key]])) {
        out <- c(out, sprintf("<details><summary>Brief of %s</summary>", researched_on[[row$key]] %||% "earlier"), "",
          research_brief_lines(research[[row$key]]), "</details>", "")
      }
    }
  }
  if (nrow(tracked_rows) > 0) {
    out <- c(out, "## Already tracked", "",
      vapply(seq_len(nrow(tracked_rows)), function(i) {
        row <- tracked_rows[i, ]
        sprintf("- %s: %.1f%% of papers (%d), trend %s%s", label(row), 100 * row$share, row$papers, row$trend,
          if (!is.null(tracked[[row$key]])) sprintf(", #%s", tracked[[row$key]]) else "")
      }, ""), "")
  }
  out
}
