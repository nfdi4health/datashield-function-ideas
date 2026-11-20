# A research brief (research_candidate()) as markdown lines for the
# candidate pull request.
research_brief_lines <- function(research) {
  pk <- vapply(research$r_packages %||% list(), function(p) sprintf("`%s::%s` (%s)", p$package, p[["function"]], p$note), "")
  out <- c(sprintf("**What it is:** %s", research$description), "",
    sprintf("**In R:** %s", if (length(pk) == 0) "no package found." else paste(pk, collapse = "; ")), "",
    sprintf("**Federated:** %s", research$federated), "",
    sprintf("**Disclosure, a first view:** %s", research$disclosure), "",
    sprintf("**Would fit:** %s", research$fit), "")
  if (length(research$sources) > 0) out <- c(out, sprintf("Sources: %s", paste(sprintf("<%s>", unlist(research$sources)), collapse = ", ")), "")
  out
}
