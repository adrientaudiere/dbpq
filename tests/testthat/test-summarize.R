test_that("list_ranks_db extracts kingdom ranks", {
  skip_if_not_installed("Biostrings")
  tmp <- tempfile(fileext = ".fasta")
  writeLines(c(
    ">seq1;k__Fungi;p__Ascomycota",
    "ATCGATCG",
    ">seq2;k__Fungi;p__Basidiomycota",
    "GCTAGCTA",
    ">seq3;k__Plantae;p__Magnoliophyta",
    "TTAATTAA"
  ), tmp)
  result <- list_ranks_db(tmp, rank_prefix = "k__")
  expect_equal(result[["k__Fungi"]], 2L)
  expect_equal(result[["k__Plantae"]], 1L)
  unlink(tmp)
})
