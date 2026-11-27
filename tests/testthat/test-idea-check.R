# The hub's "Exists?" check of new issues (R/check_ideas.R): Claude and
# the inventory as stand-ins.

idea_settings <- function() read_config_yaml("config/idea-check.yml")
idea_inventory <- function() data.frame(
  package = c("dsBaseClient", "dsClusterClient", "dsBaseClient"),
  fn = c("ds.glm", "ds.kmedoids", "ds.mean"),
  title = c("Fits a generalized linear model", "K-medoids clustering of the pooled data", "Computes the mean"),
  description = c("Pooled GLM over studies.", "Partitions participants into k clusters around medoids.", "Mean of a vector."),
  status = c("production", "development", "production"), stringsAsFactors = FALSE)
idea_client <- function(prompt) list(config = list(model = "m"), prompt = prompt, auth = NULL)
reader <- idea_client("{{NUMBER}} {{TITLE}} {{BODY}} {{OTHERS}}")
judge <- idea_client("{{METHODS}}")
issue <- list(number = 7, title = "Missing DataSHIELD function: k-medoids", body = "Cluster participants with PAM.")
others <- list(list(number = 7, title = "self"), list(number = 3, title = "PAM clustering"), list(number = 4, title = "Other"))

answers <- function(read, judged) {
  local_global_mock(call_claude_tool = function(claude, tool, prompt) {
    if (identical(tool$input_schema$properties$is_method$type, "boolean")) read else judged
  }, env = parent.frame())
}

test_that("check_idea() keeps a checked development match and only listed similar issues", {
  answers(list(is_method = TRUE, method = "k-medoids clustering", description = "Clusters around medoids.",
      keywords = list("medoids", "pam"), similar = list(3L, 99L, 7L)),
    list(methods = list(list(id = "m1", verdict = "yes", `function` = "dsClusterClient::ds.kmedoids",
      quote = "K-medoids clustering", note = ""))))
  x <- check_idea(issue, others, idea_inventory(), reader, judge, idea_settings(), as.Date("2026-11-17"))
  expect_false(x$limit)
  expect_equal(x$result$verdict$verdict, "development")
  expect_equal(x$result$verdict[["function"]], "dsClusterClient::ds.kmedoids")
  expect_equal(x$result$similar, 3L)
  c <- format_idea_comment(x$result, idea_settings(), as.Date("2026-11-17"))
  expect_equal(c$label, "in-development")
  expect_match(c$body, "Only in development: `dsClusterClient::ds.kmedoids`", fixed = TRUE)
  expect_match(c$body, "Similar ideas here: #3.", fixed = TRUE)
  expect_match(c$body, "<!-- idea-check: development -->", fixed = TRUE)
})

test_that("an invented quote becomes unconfirmed, without a label", {
  answers(list(is_method = TRUE, method = "k-medoids clustering", description = "", keywords = list("medoids"), similar = list()),
    list(methods = list(list(id = "m1", verdict = "yes", `function` = "dsClusterClient::ds.kmedoids",
      quote = "does everything you want", note = ""))))
  x <- check_idea(issue, others, idea_inventory(), reader, judge, idea_settings(), as.Date("2026-11-17"))
  expect_equal(x$result$verdict$verdict, "unconfirmed")
  expect_equal(format_idea_comment(x$result, idea_settings(), as.Date("2026-11-17"))$label, "")
})

test_that("a production match is labelled exists, partly exists-partly", {
  s <- idea_settings()
  inv <- idea_inventory()
  r <- list(number = 7, method = "pooled GLM", similar = integer(0), candidates = inv[1, ],
    verdict = list(verdict = "yes", `function` = "dsBaseClient::ds.glm", quote = "generalized linear model", note = ""))
  expect_equal(format_idea_comment(r, s, Sys.Date())$label, "exists")
  r$verdict$verdict <- "partial"
  r$verdict$note <- "No random effects."
  c <- format_idea_comment(r, s, Sys.Date())
  expect_equal(c$label, "exists-partly")
  expect_match(c$body, "Note: No random effects.", fixed = TRUE)
})

test_that("no candidates gives none without asking the judge; not a method gives a short comment", {
  calls <- 0
  local_global_mock(call_claude_tool = function(claude, tool, prompt) {
    calls <<- calls + 1
    list(is_method = TRUE, method = "zzz quux", description = "", keywords = list("qqq"), similar = list())
  })
  x <- check_idea(issue, others, idea_inventory(), reader, judge, idea_settings(), Sys.Date())
  expect_equal(calls, 1)
  expect_equal(x$result$verdict$verdict, "none")
  local_global_mock(call_claude_tool = function(claude, tool, prompt) {
    list(is_method = FALSE, method = "", description = "", keywords = list(), similar = list())
  })
  x <- check_idea(issue, others, idea_inventory(), reader, judge, idea_settings(), Sys.Date())
  c <- format_idea_comment(x$result, idea_settings(), Sys.Date())
  expect_match(c$body, "doesn't read as a statistical method", fixed = TRUE)
  expect_match(c$body, "<!-- idea-check: not-method -->", fixed = TRUE)
  expect_equal(c$label, "")
})

test_that("Claude's text in the comment can't mention or link", {
  r <- list(number = 7, method = "ping @alice https://evil.example", similar = integer(0),
    candidates = idea_inventory()[0, ], verdict = list(verdict = "none", `function` = "", quote = "", note = "see @bob"))
  body <- format_idea_comment(r, idea_settings(), Sys.Date())$body
  expect_false(grepl("@alice", body, fixed = TRUE))
  expect_false(grepl("@bob", body, fixed = TRUE))
  expect_false(grepl("https://evil", body, fixed = TRUE))
})

test_that("a usage limit or a failed call leaves the issue for the next run", {
  local_global_mock(call_claude_tool = function(claude, tool, prompt) stop("Claude AI usage limit reached|1763400000"))
  x <- check_idea(issue, others, idea_inventory(), reader, judge, idea_settings(), Sys.Date())
  expect_true(x$limit)
  expect_null(x$result)
  local_global_mock(call_claude_tool = function(claude, tool, prompt) stop("HTTP 500"))
  x <- check_idea(issue, others, idea_inventory(), reader, judge, idea_settings(), Sys.Date())
  expect_true(x$failed)
  expect_null(x$result)
})

test_that("match_vocabulary_method() matches only exact names, keys and method names", {
  v <- list(methods = list(), names = list(), variant_names = list())
  v$methods[["k-medoids"]] <- list(name = "k-medoids clustering")
  v$methods[["cox-regression"]] <- list(name = "Cox regression", variants = list(stratified = list(name = "stratified")))
  v$names[["pam clustering"]] <- list(method = "k-medoids")
  v$names[["stratified cox model"]] <- list(method = "cox-regression", variant = "stratified")
  v$names[["p-value"]] <- list(method = "")
  v$variant_names[["cox-regression"]][["stratified"]] <- list(variant = "stratified")
  expect_equal(match_vocabulary_method(v, "PAM clustering."), "k-medoids")
  expect_equal(match_vocabulary_method(v, "K-Medoids Clustering"), "k-medoids")
  expect_equal(match_vocabulary_method(v, "k-medoids"), "k-medoids")
  expect_equal(match_vocabulary_method(v, "Stratified Cox model"), "cox-regression/stratified")
  expect_equal(match_vocabulary_method(v, "p-value"), "")
  expect_equal(match_vocabulary_method(v, "medoids"), "")
  expect_equal(match_vocabulary_method(v, "clustering around medoids"), "")
})

idea_vocab <- function() {
  v <- list(methods = list(), names = list(), variant_names = list())
  v$methods[["k-medoids"]] <- list(name = "k-medoids clustering", description = "Partitions around medoids.",
    keywords = list("pam", "medoids"))
  v$methods[["cluster-analysis"]] <- list(name = "Cluster analysis", description = "Groups similar participants.",
    keywords = list("clustering", "k-means"))
  v$names[["pam"]] <- list(method = "k-medoids")
  v$names[["k-means"]] <- list(method = "cluster-analysis")
  v$names[["lasso"]] <- list(method = "")
  v
}
idea_reg <- function() {
  reg <- new.env()
  reg$papers <- list(
    `1` = list(pmid = "1", usable = TRUE, month = "2024-05", found_by = list(cancer = list()), methods = list(list(name = "pam"))),
    `2` = list(pmid = "2", usable = TRUE, month = "2025-03", found_by = list(metabolic = list()), methods = list(list(name = "lasso"))),
    `3` = list(pmid = "3", usable = TRUE, month = "2025-04", found_by = list(cancer = list()), methods = list(list(name = "k-means"))),
    `4` = list(pmid = "4", usable = FALSE, month = "2025-04", methods = list()))
  reg
}
matcher <- idea_client("{{METHOD}} {{CANDIDATES}}")
months <- watch_months(as.Date("2026-11-26"), 0, 5)
recent <- utils::head(months, 36)

test_that("an exact name match gets the numbers and the literature watch's marker, without asking Claude", {
  local_global_mock(call_claude_tool = function(claude, tool, prompt) stop("not asked"))
  r <- list(number = 7, method = "PAM", description = "", keywords = character(0), similar = integer(0),
    candidates = idea_inventory()[0, ], verdict = list(verdict = "none", `function` = "", quote = "", note = ""))
  lit <- match_idea_literature(matcher, r, idea_vocab())
  expect_equal(lit[c("key", "exact")], list(key = "k-medoids", exact = TRUE))
  st <- idea_literature_stats(idea_reg(), idea_vocab(), lit$key, months, recent)
  expect_equal(st$papers, 1)
  expect_equal(st$usable, 3)
  expect_equal(st$fields, "cancer")
  r$literature <- c(lit, name = "k-medoids clustering", st)
  body <- format_idea_comment(r, idea_settings(), Sys.Date())$body
  expect_match(body, "knows this method by this name", fixed = TRUE)
  expect_match(body, "named in 1 of the 3 usable papers read so far (33.3%", fixed = TRUE)
  expect_match(body, "Mostly in: cancer.", fixed = TRUE)
  expect_match(body, "<!-- literature-watch-method: k-medoids -->", fixed = TRUE)
})

test_that("a match by meaning shows the numbers, labelled as Claude's, without the marker", {
  seen <- NULL
  local_global_mock(call_claude_tool = function(claude, tool, prompt) {
    seen <<- prompt
    list(key = "cluster-analysis", variant = "", relation = "broader", note = "Covers more than k-medoids.")
  })
  r <- list(number = 7, method = "partitioning around medoids", description = "Clusters around medoids.",
    keywords = c("clustering"), similar = integer(0), candidates = idea_inventory()[0, ],
    verdict = list(verdict = "none", `function` = "", quote = "", note = ""))
  lit <- match_idea_literature(matcher, r, idea_vocab())
  expect_equal(lit[c("key", "exact", "relation")], list(key = "cluster-analysis", exact = FALSE, relation = "broader"))
  expect_match(seen, "- cluster-analysis: Cluster analysis.", fixed = TRUE)
  r$literature <- c(lit, name = "Cluster analysis", idea_literature_stats(idea_reg(), idea_vocab(), lit$key, months, recent))
  body <- format_idea_comment(r, idea_settings(), Sys.Date())$body
  expect_match(body, "has a broader method, by Claude's match: Cluster analysis, named in 1 of the 3", fixed = TRUE)
  expect_match(body, "Note: Covers more than k-medoids.", fixed = TRUE)
  expect_false(grepl("literature-watch-method", body, fixed = TRUE))
})

test_that("no fit, an unlisted key or nothing close gives no numbers; a limit stops", {
  r <- list(number = 7, method = "partitioning around medoids", description = "", keywords = c("clustering"))
  local_global_mock(call_claude_tool = function(claude, tool, prompt) list(key = "", variant = "", relation = "none", note = ""))
  expect_null(match_idea_literature(matcher, r, idea_vocab()))
  local_global_mock(call_claude_tool = function(claude, tool, prompt) list(key = "lasso", variant = "", relation = "same", note = ""))
  expect_null(match_idea_literature(matcher, r, idea_vocab()))
  local_global_mock(call_claude_tool = function(claude, tool, prompt) stop("not asked"))
  expect_null(match_idea_literature(matcher, list(number = 7, method = "zzz quux", keywords = "qqq"), idea_vocab()))
  expect_null(match_idea_literature(matcher, r, NULL))
  local_global_mock(call_claude_tool = function(claude, tool, prompt) stop("Claude AI usage limit reached|1763400000"))
  expect_true(match_idea_literature(matcher, r, idea_vocab())$limit)
})

test_that("a hand-written idea gets a research brief as plain text; a failed call says so", {
  seen <- NULL
  local_global_mock(call_claude_tool = function(claude, tool, prompt) {
    seen <<- prompt
    list(description = "Clusters around medoids. Ping @alice", federated = "Iterative, sums per cluster.",
      disclosure = "Medoids are individual rows: see https://evil.example", fit = "dsClusterClient.",
      r_packages = list(list(package = "cluster", `function` = "pam", note = "the classic")),
      sources = list("https://cran.r-project.org/package=cluster", "not a url"))
  })
  researcher <- idea_client("{{CANDIDATE}}")
  iss <- list(number = 7, title = "k-medoids please", body = "We cluster participants with PAM.")
  r <- list(number = 7, method = "k-medoids clustering", description = "Clusters around medoids.", similar = integer(0),
    candidates = idea_inventory()[0, ], verdict = list(verdict = "none", `function` = "", quote = "", note = ""))
  res <- research_idea(researcher, iss, r, NULL)
  expect_false(res$limit)
  expect_match(seen, "Asked for in a hub issue by a person (actual demand)", fixed = TRUE)
  expect_match(seen, "We cluster participants with PAM.", fixed = TRUE)
  expect_length(res$research$sources, 1)
  r$research <- res$research
  body <- format_idea_comment(r, idea_settings(), Sys.Date())$body
  expect_match(body, "**A first brief**", fixed = TRUE)
  expect_match(body, "cluster::pam (the classic)", fixed = TRUE)
  expect_false(grepl("@alice", body, fixed = TRUE))
  expect_false(grepl("https://evil", body, fixed = TRUE))
  expect_false(grepl("https://cran", body, fixed = TRUE))
  expect_match(body, "Sources (copy to open):", fixed = TRUE)
  r$research <- NULL
  r$research_failed <- TRUE
  expect_match(format_idea_comment(r, idea_settings(), Sys.Date())$body, "No brief this time", fixed = TRUE)
  local_global_mock(call_claude_tool = function(claude, tool, prompt) stop("Claude AI usage limit reached|1763400000"))
  expect_true(research_idea(researcher, iss, r, NULL)$limit)
})

test_that("the inventory is read from the catalogue's packages.json", {
  pk <- list(
    dsBaseClient = list(input = list(status = "production"), repo = list(function_info = list(roxygen_tags = list(
      list(`function` = "ds.glm", tags = list(title = list("Fits a generalised\n linear model"), description = list("Pooled over studies."), export = list(""))),
      list(`function` = "ds.mean", tags = list(`_intro` = list("Computes the mean. Of a numeric vector."))),
      list(`function` = "glmDS2", tags = list(title = list("Server side"), export = list(""))),
      list(`function` = "helper", tags = list(title = list("Not exported"))),
      list(`function` = "exportedHelper", tags = list(title = list("A helper"), export = list(""))),
      list(`function` = NULL, tags = list(title = list("No function"))),
      list(`function` = "ds.todo", tags = list(title = list("XXXX"))))))),
    dsOld = list(input = list(status = "retired"), repo = list(function_info = list(roxygen_tags = list(
      list(`function` = "ds.old", tags = list(title = list("Old"))))))),
    dsBroken = list(input = list(status = "development"), repo = list(function_info = "Error")),
    dsUnread = list(input = list(status = "development"), repo = "Error"),
    dsNamespace = list(input = list(status = "development"), repo = list(functions_exported_in_NAMESPACE = list("initProject"),
      function_info = list(roxygen_tags = list(
        list(`function` = "initProject", tags = list(title = list("Initiate a project"))),
        list(`function` = "internal_confirm", tags = list(title = list("Ask the user"))))))))
  inv <- inventory_from_packages(pk)
  expect_equal(inv$fn, c("ds.glm", "ds.mean", "exportedHelper", "ds.todo", "ds.old", "initProject"))
  expect_equal(inv$title[1], "Fits a generalised linear model")
  expect_equal(inv$description[1:2], c("Pooled over studies.", "Of a numeric vector."))
  expect_equal(inv$title[2], "Computes the mean.")
  expect_equal(unique(inv$status), c("production", "retired", "development"))
  local_global_mock(inventory_from_packages = inventory_from_packages)
  text <- jsonlite::toJSON(pk, auto_unbox = TRUE, null = "null")
  local_mocked_bindings(req_perform = function(req, ...) structure(list(), class = "fake"),
    resp_body_string = function(resp, ...) text, .package = "httr2")
  out <- read_function_inventory(list(exists = list(functions_url = "https://example.org/packages.json")))
  expect_equal(out$fn, c("ds.glm", "ds.mean", "exportedHelper", "initProject"))
  expect_true(is_server_function("vcovDS.coxph") && is_server_function("meanDS") && !is_server_function("ds.mean"))
})
