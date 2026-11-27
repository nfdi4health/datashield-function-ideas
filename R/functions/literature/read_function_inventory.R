# The DataSHIELD functions "Exists?" checks against: the catalogue's
# inventory (FederatedMethods/packages). Since 2026-11-18 it publishes one
# packages.json (packages.datashield.org): per package its `input` (status,
# links) and `repo$function_info$roxygen_tags`, the roxygen blocks of its
# R files ({function, tags: {title, description, _intro, export, ...}});
# the old datashield_functions_metadata.json was deleted then (the idea
# check found it gone, 2026-11-27). The older format, a table of functions
# with package_list.csv for the status, is still read if `functions_url`
# points to one.
# Kept: client functions (names starting with "ds.") and other exported
# functions; left out are server functions (names ending in DS, DS1, DS2
# or DS.<suffix>, e.g. glmDS2, vcovDS.coxph), retired packages and
# placeholder documentation ("XXXX"). A data frame of package, fn, title,
# description, status; NULL if it can't be read (the step is then skipped
# for this run).
read_function_inventory <- function(settings) {
  e <- settings$exists
  fetch <- function(url) {
    tryCatch(httr2::resp_body_string(httr2::req_perform(httr2::req_retry(httr2::request(url), max_tries = 3))),
      error = function(err) {
        message(sprintf("Could not read %s: %s", url, conditionMessage(err)))
        NULL
      })
  }
  text <- fetch(e$functions_url %||% "https://packages.datashield.org/packages.json")
  if (is.null(text)) return(NULL)
  parsed <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(err) {
    message(sprintf("The function inventory isn't valid JSON: %s", conditionMessage(err)))
    NULL
  })
  if (is.null(parsed)) return(NULL)
  is_packages <- length(parsed) > 0 && !is.null(names(parsed)) && all(vapply(parsed, function(p) is.list(p) && !is.null(p$input), logical(1)))
  out <- if (is_packages) inventory_from_packages(parsed) else {
    packages <- fetch(e$packages_url %||% "https://raw.githubusercontent.com/FederatedMethods/packages/main/package_list.csv")
    if (is.null(packages)) return(NULL)
    inventory_from_table(jsonlite::fromJSON(text, simplifyVector = TRUE), packages, e)
  }
  placeholder <- function(x) !nzchar(trimws(x)) | grepl("^X+$", trimws(x))
  out <- out[out$status != "retired" & !(placeholder(out$title) & placeholder(out$description)), , drop = FALSE]
  rownames(out) <- NULL
  if (nrow(out) == 0) {
    message("The function inventory has no functions.")
    return(NULL)
  }
  out
}
