# The literature watch's methods that may be the one a hub issue asks for,
# for Claude to choose from (match_idea_literature()): the vocabulary's
# methods as a table preselect_functions() can score (fn = the key, title =
# the name, description = the description and keywords), at most `n`, best
# first. An empty table without a vocabulary or without a shared word.
idea_vocabulary_candidates <- function(vocab, words, n = 12) {
  empty <- data.frame(package = character(0), fn = character(0), title = character(0), description = character(0),
    stringsAsFactors = FALSE)
  if (is.null(vocab) || length(vocab$methods) == 0) return(empty)
  m <- vocab$methods
  table <- data.frame(package = "", fn = names(m),
    title = vapply(m, function(x) x$name %||% "", ""),
    description = vapply(m, function(x) paste(c(x$description %||% "", unlist(x$keywords)), collapse = " "), ""),
    stringsAsFactors = FALSE, row.names = NULL)
  preselect_functions(table, words, n)
}
