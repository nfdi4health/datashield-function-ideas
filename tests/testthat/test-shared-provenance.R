# Provenance: which models, prompts and configs a run used.

test_that("short_hash() tells versions apart and keeps no '--'", {
  expect_false(identical(short_hash("a"), short_hash("b")))
  expect_equal(nchar(short_hash(list(1, 2))), 10)
  expect_false(grepl("--", short_hash("a--b"), fixed = TRUE))
})

test_that("reading a prompt or config records it", {
  withr::local_options(bot.provenance = NULL)
  read_config_yaml("config/claude.yml")
  expect_true("config/claude.yml" %in% names(getOption("bot.provenance")$config))
})
