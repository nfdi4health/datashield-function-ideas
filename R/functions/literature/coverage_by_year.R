# What the candidates rest on (user, 2026-11-20: all papers read so far, not
# the current round's progress): papers read and usable per publication
# year, newest year first, from the register (read_register()).
coverage_by_year <- function(reg) {
  papers <- reg$papers
  if (length(papers) == 0) return(data.frame(year = character(0), read = integer(0), usable = integer(0)))
  year <- substr(vapply(papers, function(p) p$month %||% "", ""), 1, 4)
  usable <- vapply(papers, function(p) isTRUE(p$usable), logical(1))
  years <- sort(unique(year[nzchar(year)]), decreasing = TRUE)
  data.frame(year = years,
    read = vapply(years, function(y) sum(year == y), integer(1), USE.NAMES = FALSE),
    usable = vapply(years, function(y) sum(year == y & usable), integer(1), USE.NAMES = FALSE))
}
