test_that("list_ranks_db extracts kingdom ranks", {
  skip_if_not_installed("Biostrings")
  tmp <- tempfile(fileext = ".fasta")
  writeLines(
    c(
      ">seq1;k__Fungi;p__Ascomycota",
      "ATCGATCG",
      ">seq2;k__Fungi;p__Basidiomycota",
      "GCTAGCTA",
      ">seq3;k__Plantae;p__Magnoliophyta",
      "TTAATTAA"
    ),
    tmp
  )
  result <- list_ranks_db(tmp, rank_prefix = "k__")
  expect_equal(result[["k__Fungi"]], 2L)
  expect_equal(result[["k__Plantae"]], 1L)
  unlink(tmp)
})

test_that("list_ranks_db works with tax_format parameter", {
  tmp <- tempfile(fileext = ".fasta")
  writeLines(
    c(
      ">seq1;tax=d:Eukaryota,k:Fungi,p:Ascomycota",
      "ATCGATCG",
      ">seq2;tax=d:Eukaryota,k:Fungi,p:Basidiomycota",
      "GCTAGCTA"
    ),
    tmp
  )
  result <- list_ranks_db(tmp, tax_format = "sintax")
  expect_equal(result[["d:Eukaryota"]], 2L)
  unlink(tmp)
})

test_that("list_ranks_db handles positional PR2 format", {
  tmp <- tempfile(fileext = ".fasta")
  writeLines(
    c(
      paste0(
        ">EU293891 Eukaryota;Archaeplastida;Chlorophyta;",
        "Chlorophyta_X;Mamiellophyceae;Mamiellales;",
        "Bathycoccaceae;Ostreococcus;Ostreococcus_tauri"
      ),
      "ATCGATCG",
      paste0(
        ">AB123456 Eukaryota;TSAR;Dinoflagellata;",
        "Dinophyceae;Gymnodiniales;Gymnodiniaceae;",
        "Gymnodiniaceae_X;Gymnodinium;Gymnodinium_sp"
      ),
      "GCTAGCTA"
    ),
    tmp
  )
  result <- list_ranks_db(tmp, tax_format = "pr2")
  expect_equal(result[["Eukaryota"]], 2L)

  # Extract Genus (position 8)
  result2 <- list_ranks_db(
    tmp,
    tax_format = "pr2",
    rank_position = 8L
  )
  expect_equal(result2[["Ostreococcus"]], 1L)
  expect_equal(result2[["Gymnodinium"]], 1L)
  unlink(tmp)
})

test_that("list_ranks_db handles positional extraction", {
  tmp <- tempfile(fileext = ".fasta")
  writeLines(
    c(
      paste0(
        ">Bacteria;Proteobacteria;Gammaproteobacteria;",
        "Enterobacterales;Enterobacteriaceae;Escherichia;"
      ),
      "ATCGATCG",
      paste0(
        ">Bacteria;Firmicutes;Bacilli;",
        "Lactobacillales;Streptococcaceae;Streptococcus;"
      ),
      "GCTAGCTA",
      paste0(
        ">Bacteria;Proteobacteria;Alphaproteobacteria;",
        "Rhizobiales;Rhizobiaceae;Rhizobium;"
      ),
      "TTAATTAA"
    ),
    tmp
  )
  # Extract by position directly (no tax_format needed)
  result <- list_ranks_db(tmp, rank_position = 1L)
  expect_equal(result[["Bacteria"]], 3L)

  result2 <- list_ranks_db(tmp, rank_position = 2L)
  expect_equal(result2[["Proteobacteria"]], 2L)
  expect_equal(result2[["Firmicutes"]], 1L)
  unlink(tmp)
})

test_that("tax_prefixes returns correct types for each format", {
  unite <- tax_prefixes("unite")
  expect_equal(unite[["k"]], "k__")
  expect_equal(length(unite), 7L)
  expect_true(is.character(unite))

  sintax <- tax_prefixes("sintax")
  expect_equal(sintax[["d"]], "d:")
  expect_equal(length(sintax), 8L)

  gg2 <- tax_prefixes("greengenes2")
  expect_equal(gg2[["d"]], "d__")
  expect_equal(length(gg2), 7L)

  pr2 <- tax_prefixes("pr2")
  expect_true(is.integer(pr2))
  expect_equal(length(pr2), 9L)
  expect_equal(names(pr2)[[8]], "Genus")
})

test_that("detect_tax_format identifies formats correctly", {
  tmp_unite <- tempfile(fileext = ".fasta")
  writeLines(
    c(">seq1;k__Fungi;p__Ascomycota", "ATCGATCG"),
    tmp_unite
  )
  expect_equal(detect_tax_format(tmp_unite), "unite")

  tmp_sintax <- tempfile(fileext = ".fasta")
  writeLines(
    c(">seq1;tax=d:Eukaryota,k:Fungi,p:Ascomycota", "ATCGATCG"),
    tmp_sintax
  )
  expect_equal(detect_tax_format(tmp_sintax), "sintax")

  tmp_gg2 <- tempfile(fileext = ".fasta")
  writeLines(
    c(">seq1;d__Bacteria;p__Proteobacteria", "ATCGATCG"),
    tmp_gg2
  )
  expect_equal(detect_tax_format(tmp_gg2), "greengenes2")

  tmp_pr2 <- tempfile(fileext = ".fasta")
  writeLines(
    c(
      paste0(
        ">EU293891 Eukaryota;Archaeplastida;",
        "Chlorophyta;Chlorophyta_X;Mamiellophyceae"
      ),
      "ATCGATCG"
    ),
    tmp_pr2
  )
  expect_equal(detect_tax_format(tmp_pr2), "pr2")

  unlink(c(tmp_unite, tmp_sintax, tmp_gg2, tmp_pr2))
})

test_that("summarize_db accepts tax_format parameter", {
  expect_true("tax_format" %in% names(formals(summarize_db)))
})
