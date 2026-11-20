# The research briefs kept on the data branch (research.json under the
# data folder), by candidate key: date, the "Exists?" verdict and the hash
# of the catalogue functions found for it at the time, and the brief
# (research_candidate()). An empty list without the file.
read_research_store <- function(dir) {
  path <- file.path(dir, "research.json")
  if (!file.exists(path)) return(list())
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}
