# The function inventory from the catalogue's packages.json (see
# read_function_inventory()): one row per documented function of a
# package, its title (the @title tag, else the first line of the text
# before the first tag) and description (@description, else the rest of
# that text), one line each. Client functions ("ds." names) and other
# exported functions are kept, server functions ("DS" names, see
# is_server_function()) and unexported helpers aren't.
inventory_from_packages <- function(packages) {
  one_line <- function(x) trimws(gsub("[[:space:]]+", " ", paste(unlist(x), collapse = " ")))
  rows <- lapply(names(packages), function(name) {
    p <- packages[[name]]
    info <- p$repo$function_info
    blocks <- if (is.list(info)) info$roxygen_tags else NULL   # "Error" when the catalogue couldn't read the package
    if (!is.list(blocks) || length(blocks) == 0) return(NULL)
    status <- tolower(trimws(p$input$status %||% ""))
    do.call(rbind, lapply(blocks, function(b) {
      fn <- b[["function"]]
      if (is.null(fn) || !nzchar(fn) || is_server_function(fn)) return(NULL)
      tags <- b$tags %||% list()
      if (!startsWith(fn, "ds.") && is.null(tags$export)) return(NULL)
      intro <- strsplit(one_line(tags[["_intro"]] %||% ""), "(?<=\\.)\\s+", perl = TRUE)[[1]]
      title <- one_line(tags$title %||% if (length(intro)) intro[1] else "")
      description <- one_line(tags$description %||% if (length(intro) > 1) paste(intro[-1], collapse = " ") else "")
      data.frame(package = name, fn = fn, title = title, description = description, status = status, stringsAsFactors = FALSE)
    }))
  })
  out <- do.call(rbind, c(list(data.frame(package = character(0), fn = character(0), title = character(0),
    description = character(0), status = character(0), stringsAsFactors = FALSE)), rows))
  out[!duplicated(paste(out$package, out$fn)), , drop = FALSE]
}
