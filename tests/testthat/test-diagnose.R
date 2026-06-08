unite_db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
sintax_db <- system.file("extdata", "example_sintax.fasta", package = "dbpq")

test_that("diagnose_db returns a structured diagnosis for one file", {
  d <- diagnose_db(unite_db, verbose = FALSE)
  expect_s3_class(d, "dbpq_diagnosis")
  expect_named(
    d,
    c("stats", "coverage", "warnings", "cross_file", "plots")
  )
  expect_equal(nrow(d$stats), 1L)
  expect_equal(d$stats$format, "unite")
  expect_true(d$stats$valid)
  expect_equal(d$stats$n_sequences, count_seq_db(unite_db))
  expect_gt(nrow(d$coverage), 0L)
  expect_true(d$cross_file$format_agreement)
})

test_that("diagnose_db flags a mixed taxonomy format across files", {
  d <- diagnose_db(c(unite_db, sintax_db), verbose = FALSE)
  expect_equal(nrow(d$stats), 2L)
  expect_false(d$cross_file$format_agreement)
  mixed <- d$warnings[d$warnings$check == "format" & is.na(d$warnings$file), ]
  expect_equal(nrow(mixed), 1L)
  expect_match(mixed$message, "Mixed taxonomy formats")
})

test_that("diagnose_db detects ambiguous bases", {
  d <- diagnose_db(sintax_db, verbose = FALSE)
  expect_gte(d$stats$n_ambiguous_seq, 1L)
  expect_gt(d$stats$pct_ambiguous_bases, 0)
})

test_that("diagnose_db flags short sequences via min_length", {
  d <- diagnose_db(unite_db, min_length = 10000L, verbose = FALSE)
  expect_gt(d$stats$n_short, 0L)
  short_warn <- d$warnings[grepl("shorter than", d$warnings$message), ]
  expect_equal(nrow(short_warn), 1L)
})

test_that("diagnose_db errors on missing or empty input", {
  expect_error(diagnose_db(character(0)), "non-empty")
  expect_error(diagnose_db("does_not_exist.fasta"), "not found")
})

test_that("diagnose_db can skip plots", {
  d <- diagnose_db(unite_db, plot = FALSE, verbose = FALSE)
  expect_null(d$plots)
})

test_that("diagnose_db builds plots when ggplot2 is available", {
  skip_if_not_installed("ggplot2")
  d <- diagnose_db(unite_db, verbose = FALSE)
  expect_s3_class(d$plots$length, "ggplot")
  expect_s3_class(d$plots$coverage, "ggplot")
})

test_that("diagnose_db counts unwanted taxonomic values in headers", {
  tmp <- tempfile(fileext = ".fasta")
  on.exit(unlink(tmp))
  writeLines(
    c(
      ">SH900|k__Fungi;p__Basidiomycota;g__unidentified;s__unclassified",
      "ATCGATCGTAGCTAGCATCGATCGTAGCTAGCATCGATCGTAGCTAGCATCG",
      ">SH901|k__Fungi;p__Ascomycota;g__Fusarium;s__Fusarium_oxysporum",
      "GCTAGCATCGATCGTAGCTAGCATCGATCGTAGCTAGCATCGATCGTAGCTA"
    ),
    tmp
  )
  d <- diagnose_db(tmp, verbose = FALSE)
  expect_gte(d$stats$n_unwanted_tax, 2L)
  unwanted_warn <- d$warnings[grepl("unwanted", d$warnings$message), ]
  expect_equal(nrow(unwanted_warn), 1L)
})

test_that("diagnose_db handles an empty database and mixed batches", {
  empty <- tempfile(fileext = ".fasta")
  on.exit(unlink(empty))
  file.create(empty)
  d <- diagnose_db(empty, verbose = FALSE)
  expect_equal(d$stats$n_sequences, 0L)
  expect_true(any(
    d$warnings$severity == "error" & grepl("empty", d$warnings$message)
  ))

  # An empty file in a batch must still bind cleanly with a populated file
  batch <- diagnose_db(c(unite_db, empty), verbose = FALSE)
  expect_equal(nrow(batch$stats), 2L)
})
