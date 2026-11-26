# Which method of the literature watch a hub issue's method is (the idea
# check, R/check_ideas.R). An exact match by name (match_vocabulary_method())
# counts as the watch's own method: exact = TRUE, and the comment gets the
# watch's marker, so the candidate list treats it as tracked. Otherwise
# Claude chooses among the vocabulary's methods sharing words with it
# (idea_vocabulary_candidates(), build_literature_match_tool()): a match by
# meaning only shows the numbers, labelled as Claude's match, and sets no
# marker (user, 2026-11-18: a wrong match must not merge two ideas; user,
# 2026-11-26: the numbers by meaning are wanted all the same). Returns
# list(key, exact, relation, note) or NULL (no vocabulary, nothing close,
# `none`, a key or variant that isn't listed), and list(limit = TRUE) at the
# usage limit.
match_idea_literature <- function(claude, result, vocab, n = 12) {
  if (is.null(vocab) || length(vocab$methods) == 0 || !nzchar(result$method %||% "")) return(NULL)
  key <- match_vocabulary_method(vocab, result$method)
  if (nzchar(key)) return(list(key = key, exact = TRUE, relation = "same", note = ""))
  cand <- idea_vocabulary_candidates(vocab, c(result$method, result$keywords), n)
  if (nrow(cand) == 0) return(NULL)
  lines <- vapply(cand$fn, function(k) {
    m <- vocab$methods[[k]]
    v <- names(m$variants %||% list())
    sprintf("- %s: %s. %s%s", k, m$name %||% k, m$description %||% "",
      if (length(v)) sprintf(" Variants: %s.", paste(v, collapse = ", ")) else "")
  }, "")
  method <- sprintf("%s. %s", result$method, result$description %||% "")
  res <- call_watch_claude(claude, build_literature_match_tool(),
    fill_template(claude$prompt, list(METHOD = method, CANDIDATES = paste(lines, collapse = "\n"))),
    sprintf("issue #%s's literature match", result$number))
  if (res$limit) return(list(limit = TRUE))
  a <- res$answer
  if (is.null(a) || !(a$relation %||% "none") %in% c("same", "broader", "narrower") || !(a$key %||% "") %in% cand$fn) return(NULL)
  key <- a$key
  variant <- a$variant %||% ""
  if (nzchar(variant) && variant %in% names(vocab$methods[[key]]$variants %||% list())) key <- paste(key, variant, sep = "/")
  list(key = key, exact = FALSE, relation = a$relation, note = a$note %||% "")
}
