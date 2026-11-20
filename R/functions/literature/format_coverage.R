# The candidate pull request's lines on what its ranking rests on
# (coverage_by_year()): all usable papers read as one sentence, and the
# papers per publication year as a folded table underneath (user,
# 2026-11-20: ten years make one line too long).
format_coverage <- function(cov) {
  if (nrow(cov) == 0) return("No papers read yet.")
  big <- function(x) vapply(x, function(v) format(v, big.mark = ","), "")
  c(sprintf("The ranking rests on %s usable papers read so far (of %s read).", big(sum(cov$usable)), big(sum(cov$read))),
    "", "<details><summary>By publication year</summary>", "",
    "| Year | Usable | Read |", "|---|--:|--:|",
    sprintf("| %s | %s | %s |", cov$year, big(cov$usable), big(cov$read)),
    "", "</details>")
}
