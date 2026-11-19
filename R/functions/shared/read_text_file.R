# Copied from nfdi4health/datashield-workflows (R/functions/shared/) on
# 2026-11-19; the hub keeps its own copy (fixes there may be needed here).
# Reads a text file (e.g. a prompt template) as a single string — see
# resolve_shared_path() for where it's looked up. Its hash goes into the
# report's provenance (record_provenance()).
read_text_file <- function(rel_path) {
  text <- paste(readLines(resolve_shared_path(rel_path), warn = FALSE), collapse = "\n")
  record_provenance("prompt", rel_path, short_hash(text))
  text
}
