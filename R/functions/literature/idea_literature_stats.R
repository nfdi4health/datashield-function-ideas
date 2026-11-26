# How much the papers read so far use a method of the literature watch
# (`key`, "method" or "method/variant"), for the idea check's comment:
# among the usable papers of `months` (each paper once, all fields) the
# number naming it and their share, the same for the `recent` months, the
# trend by year (method_trend()), and the fields finding it most (at most
# three). As in rank_candidates(), so the numbers compare with the
# candidates'.
idea_literature_stats <- function(reg, vocab, key, months, recent) {
  papers <- Filter(function(p) isTRUE(p$usable) && p$month %in% months, reg$papers %||% list())
  has <- vapply(papers, function(p) {
    m <- paper_methods(p, vocab)
    key %in% c(m$method, paste(m$method, m$variant, sep = "/")[m$variant != ""])
  }, logical(1))
  in_recent <- vapply(papers, function(p) p$month %in% recent, logical(1))
  year <- substr(vapply(papers, function(p) p$month, ""), 1, 4)
  years <- sort(unique(substr(months, 1, 4)))
  found <- unlist(lapply(papers[has], function(p) names(p$found_by)))
  list(papers = sum(has), usable = length(papers), share = if (length(papers)) sum(has) / length(papers) else 0,
    recent_share = if (sum(in_recent)) sum(has & in_recent) / sum(in_recent) else 0,
    trend = method_trend(as.numeric(years), vapply(years, function(y) sum(has & year == y), numeric(1)),
      vapply(years, function(y) sum(year == y), numeric(1))),
    fields = names(utils::head(sort(table(found), decreasing = TRUE), 3)))
}
