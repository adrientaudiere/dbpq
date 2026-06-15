test_that("find_vsearch returns a character string", {
  res <- find_vsearch()
  expect_type(res, "character")
  # May be "" (empty string from Sys.which) or a path — both are character
})

test_that("find_vsearch returns provided path", {
  res <- find_vsearch("/usr/bin/vsearch")
  expect_equal(res, "/usr/bin/vsearch")
})

test_that("is_vsearch_installed returns logical", {
  res <- is_vsearch_installed()
  expect_type(res, "logical")
  expect_length(res, 1)
})

test_that("add_sh_to_taxonomy errors when vsearch is not installed", {
  expect_error(
    add_sh_to_taxonomy(
      query_fasta = "dummy.fasta",
      unite_db = "dummy.fasta",
      vsearchpath = "/nonexistent/vsearch"
    ),
    "vsearch is not found at"
  )
})

test_that("add_sh_to_taxonomy errors when query_fasta does not exist", {
  skip_if_not(is_vsearch_installed())

  expect_error(
    add_sh_to_taxonomy(
      query_fasta = "nonexistent_query.fasta",
      unite_db = "nonexistent_db.fasta"
    ),
    "Query FASTA file not found"
  )
})

test_that("add_sh_to_taxonomy errors when unite_db does not exist", {
  skip_if_not(is_vsearch_installed())

  fasta <- system.file("extdata", "example_unite.fasta", package = "dbpq")

  expect_error(
    add_sh_to_taxonomy(
      query_fasta = fasta,
      unite_db = "nonexistent_db.fasta"
    ),
    "UNITE database file not found"
  )
})

test_that("add_sh_to_taxonomy returns results with example FASTA", {
  skip_if_not(is_vsearch_installed())

  fasta <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  res <- add_sh_to_taxonomy(
    query_fasta = fasta,
    unite_db = fasta,
    id = 1.0
  )

  expect_s3_class(res, "data.frame")
  expect_gt(nrow(res), 0)
  expect_true("query" %in% names(res))
  expect_true("sh_name" %in% names(res))
  expect_true("target" %in% names(res))
  expect_true("pct_id" %in% names(res))
  expect_true("aln_len" %in% names(res))
})
