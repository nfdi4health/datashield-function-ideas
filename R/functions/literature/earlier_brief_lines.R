# An earlier brief (read_research_store()) as lines for the research
# prompt, so Claude starts from it and looks for what is new since then.
earlier_brief_lines <- function(entry) {
  r <- entry$research
  pk <- vapply(r$r_packages %||% list(), function(p) sprintf("%s::%s (%s)", p$package, p[["function"]], p$note), "")
  c("", sprintf("Earlier brief of %s (start from it: keep what still holds, add what is new since then, correct what no longer holds):", entry$date),
    sprintf("- description: %s", r$description), sprintf("- R packages: %s", if (length(pk)) paste(pk, collapse = "; ") else "none found"),
    sprintf("- federated: %s", r$federated), sprintf("- disclosure: %s", r$disclosure), sprintf("- fit: %s", r$fit),
    sprintf("- sources: %s", paste(unlist(r$sources), collapse = ", ")))
}
