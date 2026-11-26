# The publication months the literature watch covers, newest first
# ("YYYY-MM"): from `lag_months` before `today`'s month (0: the current
# month; its late papers are found by the re-search of the newest months,
# `recheck_months`) back over `years_back` years.
watch_months <- function(today, lag_months = 0, years_back = 5) {
  first <- as.Date(format(as.Date(today), "%Y-%m-01"))
  newest <- if (lag_months > 0) seq(first, by = sprintf("-%d months", lag_months), length.out = 2)[2] else first
  format(seq(newest, by = "-1 month", length.out = years_back * 12), "%Y-%m")
}
