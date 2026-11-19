# Runs the unit tests of R/functions/literature and the entry scripts
# (this repository isn't an R package), from the repository root:
#   Rscript tests/testthat.R
# Needs datashield-workflows (its R/functions/shared and config/claude.yml):
# in .shared-workflows, next to this repository, or in DATASHIELD_WORKFLOWS.
# Packages: testthat, withr, httr2, jsonlite, yaml, purrr, xml2, openssl.
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
