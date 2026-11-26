# The comment of the hub's "Exists?" check on one issue (check_idea()'s
# result), with the hidden marker `<!-- idea-check: VERDICT -->` that
# tells later runs the issue is done. Everything Claude wrote (the method's
# name, the note) and the catalogue's texts pass plain_comment_text(), so
# the comment can mention, link or show nothing. A method the literature
# watch knows (`result$literature`: match_idea_literature() and
# idea_literature_stats()) gets its numbers; only an exact match also gets
# the watch's marker <!-- literature-watch-method: KEY -->, which the
# candidate list reads from bots' comments as tracked, while a match by
# Claude is labelled as such. `result$research` (research_idea()) adds the
# brief, every field as plain text, sources included (readable, not links);
# `result$research_failed` a line that it couldn't be written. Returns
# list(body, label).
format_idea_comment <- function(result, settings, today) {
  s <- settings
  t <- s$texts
  plain <- function(x, n = s$max_note_chars %||% 300) plain_comment_text(x %||% "", n)
  lines <- t$heading
  rec <- result$verdict
  verdict <- if (is.null(rec)) "not-method" else rec$verdict
  if (is.null(rec)) {
    lines <- c(lines, "", t$not_method)
  } else {
    lines <- c(lines, "", sprintf(t$read_as, plain(result$method, 120)))
    template <- t$verdicts[[verdict]] %||% t$verdicts$unclear
    line <- if (verdict %in% c("yes", "partial", "development")) {
      sprintf(template, gsub("`", "", rec[["function"]]), plain(rec$quote))
    } else {
      template
    }
    lines <- c(lines, line)
    if (nzchar(trimws(rec$note %||% ""))) lines <- c(lines, sprintf(t$note, plain(rec$note)))
    cand <- utils::head(result$candidates, s$closest %||% 5)
    if (nrow(cand) > 0) {
      lines <- c(lines, "", t$closest, sprintf("- `%s::%s`%s: %s", cand$package, cand$fn,
        ifelse(nzchar(cand$status), sprintf(" (%s)", cand$status), ""), vapply(cand$title, plain, "", n = 160)))
    }
  }
  lit <- result$literature
  if (!is.null(lit)) {
    numbers <- sprintf(t$literature_numbers, lit$papers, lit$usable, 100 * lit$share, 100 * lit$recent_share,
      t$trends[[lit$trend]] %||% lit$trend)
    if (length(lit$fields)) numbers <- paste(numbers, sprintf(t$literature_fields, paste(lit$fields, collapse = ", ")))
    if (isTRUE(lit$exact)) {
      lines <- c(lines, "", paste(t$literature_exact, numbers))
    } else {
      name <- plain(lit$name %||% lit$key, 120)
      lines <- c(lines, "", paste(sprintf(t$literature_close[[lit$relation]] %||% t$literature_close$same, name), numbers))
      if (nzchar(trimws(lit$note %||% ""))) lines <- c(lines, sprintf(t$note, plain(lit$note)))
    }
  }
  r <- result[["research"]]
  if (!is.null(r)) {
    n <- s$max_brief_chars %||% 700
    pk <- vapply(r$r_packages %||% list(), function(p) sprintf("%s::%s (%s)", plain(p$package, 60), plain(p[["function"]], 60),
      plain(p$note, 160)), "")
    lines <- c(lines, "", t$brief_heading, "",
      sprintf(t$brief$description, plain(r$description, n)), "",
      sprintf(t$brief$r, if (length(pk)) paste(pk, collapse = "; ") else t$brief$no_package), "",
      sprintf(t$brief$federated, plain(r$federated, n)), "",
      sprintf(t$brief$disclosure, plain(r$disclosure, n)), "",
      sprintf(t$brief$fit, plain(r$fit, n)))
    if (length(r$sources)) lines <- c(lines, "", sprintf(t$brief$sources, paste(vapply(unlist(r$sources), plain, "", n = 200), collapse = " · ")))
  } else if (isTRUE(result$research_failed)) {
    lines <- c(lines, "", t$brief_failed)
  }
  if (length(result$similar)) {
    lines <- c(lines, "", sprintf(t$similar, paste0("#", result$similar, collapse = ", ")))
  }
  lines <- c(lines, "", sprintf("<sub>%s</sub>", sprintf(t$footer, format(today))), "",
    sprintf("<!-- idea-check: %s -->", verdict),
    if (isTRUE(lit$exact)) sprintf("<!-- literature-watch-method: %s -->", lit$key))
  list(body = paste(lines, collapse = "\n"), label = s$labels[[verdict]] %||% "")
}
