unite_db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
sintax_db <- system.file("extdata", "example_sintax.fasta", package = "dbpq")

test_that("profile_db returns richness for a single database", {
  p <- profile_db(unite_db, verbose = FALSE)
  expect_s3_class(p, "dbpq_profile")
  expect_s3_class(p$diagnosis, "dbpq_diagnosis")
  expect_true(all(
    c("file", "rank", "n_levels", "n_seqs_annotated") %in% names(p$richness)
  ))
  # All five UNITE example sequences are k__Fungi: one kingdom-level taxon
  k <- p$richness[p$richness$rank == "k", ]
  expect_equal(k$n_levels, 1L)
  expect_equal(k$n_seqs_annotated, count_seq_db(unite_db))
  expect_null(p$comparison)
})

test_that("profile_db builds a richness plot when ggplot2 is available", {
  skip_if_not_installed("ggplot2")
  p <- profile_db(unite_db, verbose = FALSE)
  expect_s3_class(p$plots$richness, "ggplot")
})

test_that("profile_db compares taxa across databases per rank", {
  p <- profile_db(c(unite_db, sintax_db), verbose = FALSE)
  expect_false(is.null(p$comparison))
  expect_true(all(
    c("rank", "members", "n_members", "n_taxa", "n_seqs") %in%
      names(p$comparison$signatures)
  ))
  # Both databases annotate kingdom = Fungi: exactly one shared kingdom taxon
  sigs <- p$comparison$signatures
  k_shared <- sigs[sigs$rank == "k" & sigs$n_members == 2, ]
  expect_equal(sum(k_shared$n_taxa), 1L)
})

test_that("cross-database signatures sum taxa and sequences correctly", {
  taxa <- tibble::tibble(
    file = c("A", "A", "B", "B"),
    rank = "g",
    taxon = c("x", "y", "x", "z"),
    n_seqs = c(10L, 5L, 3L, 8L)
  )
  cmp <- compare_taxa_across_db(taxa, build_plots = FALSE)
  sigs <- cmp$signatures
  shared <- sigs[sigs$members == "A & B", ]
  expect_equal(shared$n_taxa, 1L)
  expect_equal(shared$n_seqs, 13L)
  a_only <- sigs[sigs$members == "A", ]
  expect_equal(a_only$n_seqs, 5L)
})

test_that("profile_db builds Venn plots for few databases", {
  skip_if_not_installed("ggVennDiagram")
  p <- profile_db(c(unite_db, sintax_db), verbose = FALSE)
  expect_true("k" %in% names(p$comparison$plots))
  expect_s3_class(p$comparison$plots[["k"]], "ggplot")
})

test_that("profile_db weights the UpSet plot by sequences", {
  skip_if_not_installed("ComplexUpset")
  skip_if_not(
    complexupset_usable(),
    "ComplexUpset is incompatible with the installed ggplot2"
  )
  p <- profile_db(
    c(unite_db, sintax_db),
    weight_by_seqs = TRUE,
    verbose = FALSE
  )
  # Weighted comparison forces an UpSet (ComplexUpset returns a patchwork)
  expect_s3_class(p$comparison$plots[["k"]], "patchwork")
})

test_that("weighted comparison falls back to Venn without usable UpSet", {
  skip_if_not_installed("ggVennDiagram")
  skip_if(complexupset_usable(), "ComplexUpset is usable; fallback not hit")
  p <- profile_db(
    c(unite_db, sintax_db),
    weight_by_seqs = TRUE,
    verbose = FALSE
  )
  # Falls back to an unweighted Venn; weighted counts stay in the table
  expect_s3_class(p$comparison$plots[["k"]], "ggplot")
  sigs <- p$comparison$signatures
  expect_true(all(sigs$n_seqs >= sigs$n_taxa))
})

test_that("profile_db errors on missing or empty input", {
  expect_error(profile_db(character(0)), "non-empty")
  expect_error(profile_db("nope.fasta"), "not found")
})
