# Writes the research briefs (read_research_store()) back, keys sorted.
write_research_store <- function(store, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  store <- store[sort(names(store))]
  jsonlite::write_json(if (length(store) == 0) structure(list(), names = character(0)) else store,
    file.path(dir, "research.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
}
