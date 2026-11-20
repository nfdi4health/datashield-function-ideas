# The candidate pull request's line on what its ranking rests on
# (coverage_by_year()): all usable papers read, and per publication year.
format_coverage <- function(cov) {
  if (nrow(cov) == 0) return("No papers read yet.")
  big <- function(x) vapply(x, function(v) format(v, big.mark = ","), "")
  sprintf("The ranking rests on %s usable papers read so far (of %s read), by publication year: %s.",
    big(sum(cov$usable)), big(sum(cov$read)),
    paste(sprintf("%s: %s", cov$year, big(cov$usable)), collapse = " · "))
}
