# The stored brief of a candidate (read_research_store()) and whether it
# can be used as it is (user, 2026-11-20): younger than `max_days`, with the
# same "Exists?" verdict and the same catalogue functions found for it
# (exists_record()'s `candidates` hash). Returns list(entry = the stored
# record or NULL, fresh = TRUE/FALSE).
research_entry <- function(store, row, vocab, today, max_days) {
  entry <- store[[row$key]]
  if (is.null(entry)) return(list(entry = NULL, fresh = FALSE))
  rec <- exists_record(vocab, row$method, row$variant)
  age <- as.numeric(today - as.Date(entry$date))
  same <- identical(entry$verdict, row$verdict) && identical(entry$candidates %||% "", rec$candidates %||% "")
  list(entry = entry, fresh = !is.na(age) && age <= max_days && same)
}
