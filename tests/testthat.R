# Runs the unit tests of R/functions/ and the entry scripts
# (this repository isn't an R package), from the repository root:
#   Rscript tests/testthat.R
# Packages: testthat, withr, httr2, jsonlite, yaml, purrr, xml2, openssl.
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
