test_that("search_taxa_db returns a DNAStringSet of matching sequences", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  res <- search_taxa_db(db, "Amanita")
  expect_s4_class(res, "DNAStringSet")
  expect_length(res, 2L)
  expect_true(all(grepl("Amanita", names(res))))
})

test_that("search_taxa_db preserves original headers (taxonomy info)", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  res <- search_taxa_db(db, "muscaria")
  expect_match(names(res)[1], "k__Fungi")
  expect_match(names(res)[1], "s__Amanita_muscaria")
})

test_that("search_taxa_db AND-matches multiple taxa parts by default", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  res <- search_taxa_db(db, c("Amanita", "muscaria"))
  expect_length(res, 1L)
  expect_match(names(res)[1], "muscaria")
})

test_that("search_taxa_db OR-matches with match = 'any'", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  res <- search_taxa_db(db, c("Amanita", "Fusarium"), match = "any")
  expect_length(res, 4L)
})

test_that("search_taxa_db is case-insensitive by default", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  expect_length(search_taxa_db(db, "amanita"), 2L)
  expect_length(search_taxa_db(db, "AMANITA"), 2L)
})

test_that("search_taxa_db respects case_sensitive = TRUE", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  expect_length(search_taxa_db(db, "amanita", case_sensitive = TRUE), 0L)
  expect_length(search_taxa_db(db, "Amanita", case_sensitive = TRUE), 2L)
})

test_that("search_taxa_db returns an empty DNAStringSet when nothing matches", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  res <- search_taxa_db(db, "NonexistentTaxon")
  expect_s4_class(res, "DNAStringSet")
  expect_length(res, 0L)
})

test_that("search_taxa_db reads gzipped FASTA files", {
  in_gz <- tempfile(fileext = ".fasta.gz")
  on.exit(unlink(in_gz), add = TRUE)
  dna <- Biostrings::DNAStringSet(c("ACGTACGTACGT", "TTTTGGGGCCCC"))
  names(dna) <- c(
    "seq1|k__Fungi;g__Amanita;s__Amanita_muscaria",
    "seq2|k__Fungi;g__Fusarium;s__Fusarium_oxysporum"
  )
  Biostrings::writeXStringSet(dna, in_gz, compress = TRUE)
  res <- search_taxa_db(in_gz, "Amanita")
  expect_s4_class(res, "DNAStringSet")
  expect_length(res, 1L)
  expect_match(names(res)[1], "Amanita")
})

test_that("search_taxa_db writes to output_path and returns invisibly", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  out <- tempfile(fileext = ".fasta")
  on.exit(unlink(out), add = TRUE)
  res <- expect_invisible(search_taxa_db(db, "Boletus", output_path = out))
  expect_s4_class(res, "DNAStringSet")
  reread <- Biostrings::readDNAStringSet(out)
  expect_length(reread, 1L)
  expect_match(names(reread)[1], "Boletus")
})

test_that("search_taxa_db writes gzip when output_path ends in .gz", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  out <- tempfile(fileext = ".fasta.gz")
  on.exit(unlink(out), add = TRUE)
  search_taxa_db(db, "Boletus", output_path = out)
  magic <- readBin(out, what = "raw", n = 2L)
  expect_equal(magic, as.raw(c(0x1f, 0x8b)))
})

test_that("search_taxa_db errors on invalid taxa", {
  db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
  expect_error(search_taxa_db(db, NULL))
  expect_error(search_taxa_db(db, character(0)))
  expect_error(search_taxa_db(db, 1L))
})
