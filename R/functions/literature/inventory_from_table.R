# The function inventory from the catalogue's older format (see
# read_function_inventory()): `fns`, a table of functions with package,
# function_name, architecture_type, title and description, and
# package_list.csv (`packages`, the text) for each package's status. Kept:
# the `exists$architectures` of `e` (client and other by default), without
# server functions (is_server_function()).
inventory_from_table <- function(fns, packages, e) {
  pk <- utils::read.delim(text = packages, sep = "|", strip.white = TRUE, na.strings = "", stringsAsFactors = FALSE)
  status <- stats::setNames(tolower(trimws(pk$status %||% rep("", nrow(pk))))[seq_len(nrow(pk))], trimws(pk$name))
  status[is.na(status)] <- ""
  keep <- fns$architecture_type %in% unlist(e$architectures %||% list("client", "other")) & !is_server_function(fns$function_name)
  fns <- fns[keep, , drop = FALSE]
  out <- data.frame(package = fns$package, fn = fns$function_name,
    title = ifelse(is.na(fns$title), "", fns$title), description = ifelse(is.na(fns$description), "", fns$description),
    stringsAsFactors = FALSE)
  out$status <- unname(ifelse(out$package %in% names(status), status[out$package], ""))
  out
}
