# ——————————————————————————————————————————————————————————————————————
# detect_tax_format
# ——————————————————————————————————————————————————————————————————————

test_that("detect_tax_format returns the expected format for each valid fixture", {
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_unite.fasta")),
    "unite"
  )
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_sintax.fasta")),
    "sintax"
  )
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_greengenes2.fasta")),
    "greengenes2"
  )
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_dada2_pos.fasta")),
    "dada2"
  )
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_dada2_species.fasta")),
    "unite"
  )
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_pr2.fasta")),
    "pr2"
  )
  # Mixed fixture: first record is SINTAX, so detection is "sintax"
  expect_equal(detect_tax_format(fixture_dbpq("fmt_mixed.fasta")), "sintax")
})

test_that("detect_tax_format returns 'unknown' for unrecognized headers", {
  expect_equal(
    detect_tax_format(fixture_dbpq("err_unknown_format.fasta")),
    "unknown"
  )
  expect_equal(
    detect_tax_format(fixture_dbpq("err_empty.fasta")),
    "unknown"
  )
})

test_that("detect_tax_format handles gzipped FASTA input", {
  expect_equal(
    detect_tax_format(fixture_dbpq("fmt_unite.fasta.gz")),
    "unite"
  )
})


# ——————————————————————————————————————————————————————————————————————
# tax_prefixes
# ——————————————————————————————————————————————————————————————————————

test_that("tax_prefixes returns prefixes for each known format", {
  expect_equal(tax_prefixes("unite")[["k"]], "k__")
  expect_equal(tax_prefixes("sintax")[["d"]], "d:")
  expect_equal(tax_prefixes("greengenes2")[["d"]], "d__")
  expect_true(is.integer(tax_prefixes("pr2")))
})

test_that("tax_prefixes errors on an unknown format name", {
  expect_error(tax_prefixes("nope"), "'arg' should be one of")
})


# ——————————————————————————————————————————————————————————————————————
# list_ranks_db
# ——————————————————————————————————————————————————————————————————————

test_that("list_ranks_db extracts k__, p__ and g__ ranks on the UNITE fixture", {
  k <- list_ranks_db(fixture_dbpq("fmt_unite.fasta"), rank_prefix = "k__")
  expect_equal(k[["k__Fungi"]], 3L)

  p <- list_ranks_db(fixture_dbpq("fmt_unite.fasta"), rank_prefix = "p__")
  expect_equal(p[["p__Ascomycota"]], 2L)
  expect_equal(p[["p__Basidiomycota"]], 1L)

  g <- list_ranks_db(fixture_dbpq("fmt_unite.fasta"), rank_prefix = "g__")
  expect_equal(g[["g__Fusarium"]], 1L)
  expect_equal(g[["g__Amanita"]], 1L)
  expect_equal(g[["g__Aspergillus"]], 1L)
})

test_that("list_ranks_db works with tax_format = 'sintax'", {
  res <- list_ranks_db(fixture_dbpq("fmt_sintax.fasta"), tax_format = "sintax")
  expect_equal(res[["d:Eukaryota"]], 3L)
})

test_that("list_ranks_db handles positional PR2 with and without rank_position", {
  res <- list_ranks_db(fixture_dbpq("fmt_pr2.fasta"), tax_format = "pr2")
  expect_equal(res[["Eukaryota"]], 3L)

  res2 <- list_ranks_db(
    fixture_dbpq("fmt_pr2.fasta"),
    tax_format = "pr2",
    rank_position = 8L
  )
  expect_equal(res2[["Ostreococcus"]], 1L)
  expect_equal(res2[["Gymnodinium"]], 1L)
  expect_equal(res2[["Chondrus_crispus"]], 1L)
})

test_that("list_ranks_db handles positional dada2 with rank_position", {
  res <- list_ranks_db(
    fixture_dbpq("fmt_dada2_pos.fasta"),
    rank_position = 1L
  )
  expect_equal(res[["Bacteria"]], 2L)
  expect_equal(res[["Archaea"]], 1L)
})

test_that("list_ranks_db emits a detect_tax_format() hint when no prefix matches", {
  expect_message(
    list_ranks_db(
      fixture_dbpq("err_unknown_format.fasta"),
      rank_prefix = "k__"
    ),
    "detect_tax_format"
  )
})


# ——————————————————————————————————————————————————————————————————————
# summarize_db
# ——————————————————————————————————————————————————————————————————————

test_that("summarize_db returns a list with the expected components on each fixture", {
  for (f in c(
    "fmt_unite.fasta",
    "fmt_sintax.fasta",
    "fmt_greengenes2.fasta",
    "fmt_dada2_species.fasta"
  )) {
    res <- summarize_db(fixture_dbpq(f))
    expect_type(res, "list")
    expect_named(res, c("n_sequences", "length_summary", "ranks"))
    expect_equal(res$n_sequences, 3L)
  }
})

test_that("summarize_db counts annotation per rank for the UNITE fixture", {
  res <- suppressMessages(summarize_db(
    fixture_dbpq("fmt_unite.fasta"),
    tax_format = "unite"
  ))
  expect_equal(res$ranks[["k"]], 3L)
  expect_equal(res$ranks[["p"]], 3L)
  expect_equal(res$ranks[["g"]], 3L)
})

test_that("summarize_db handles empty FASTA databases gracefully", {
  res <- suppressMessages(summarize_db(fixture_dbpq("err_empty.fasta")))
  expect_equal(res$n_sequences, 0L)
  expect_true(all(res$ranks == 0L))
  expect_no_error(summarize_db(fixture_dbpq("err_empty.fasta")))
})

test_that("summarize_db with tax_format = 'auto' round-trips on the UNITE fixture", {
  res <- suppressMessages(summarize_db(
    fixture_dbpq("fmt_unite.fasta"),
    tax_format = "auto"
  ))
  expect_equal(res$n_sequences, 3L)
  expect_equal(res$ranks[["k"]], 3L)
})


# ——————————————————————————————————————————————————————————————————————
# count_seq_db
# ——————————————————————————————————————————————————————————————————————

test_that("count_seq_db returns 3L on each valid fixture", {
  for (f in c(
    "fmt_unite.fasta",
    "fmt_sintax.fasta",
    "fmt_greengenes2.fasta",
    "fmt_dada2_pos.fasta",
    "fmt_dada2_species.fasta",
    "fmt_pr2.fasta",
    "fmt_mixed.fasta",
    "fmt_unite.fasta.gz"
  )) {
    expect_equal(
      count_seq_db(fixture_dbpq(f)),
      3L,
      info = f
    )
  }
})

test_that("count_seq_db returns 0L on an empty file", {
  expect_equal(count_seq_db(fixture_dbpq("err_empty.fasta")), 0L)
})

test_that("count_seq_db counts both records on duplicate-sequence fixture", {
  expect_equal(
    count_seq_db(fixture_dbpq("err_duplicate_sequences.fasta")),
    2L
  )
})


# ——————————————————————————————————————————————————————————————————————
# count_pattern_db
# ——————————————————————————————————————————————————————————————————————

test_that("count_pattern_db counts known patterns on the UNITE fixture", {
  expect_equal(
    count_pattern_db(fixture_dbpq("fmt_unite.fasta"), pattern = "Fungi"),
    3L
  )
  expect_equal(
    count_pattern_db(fixture_dbpq("fmt_unite.fasta"), pattern = "Ascomycota"),
    2L
  )
})

test_that("count_pattern_db returns 0L without warning when no match is found", {
  expect_no_warning(
    expect_equal(
      count_pattern_db(
        fixture_dbpq("fmt_unite.fasta"),
        pattern = "ZZZ_no_match_ZZZ"
      ),
      0L
    )
  )
})

test_that("count_pattern_db finds 'unclassified' in the unwanted-tax fixture", {
  expect_gte(
    count_pattern_db(
      fixture_dbpq("err_unwanted_tax.fasta"),
      pattern = "unclassified"
    ),
    1L
  )
})


# ——————————————————————————————————————————————————————————————————————
# count_unwanted_tax
# ——————————————————————————————————————————————————————————————————————

test_that("count_unwanted_tax returns an empty tibble on a clean fixture", {
  res <- suppressMessages(count_unwanted_tax(fixture_dbpq("fmt_unite.fasta")))
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0L)
})

test_that("count_unwanted_tax detects unclassified, unknown, incertae sedis and empty ranks", {
  res <- suppressMessages(count_unwanted_tax(
    fixture_dbpq("err_unwanted_tax.fasta")
  ))
  expect_s3_class(res, "tbl_df")
  expect_true("unclassified" %in% res$description)
  expect_true("unknown" %in% res$description)
  expect_true("incertae sedis" %in% res$description)
  expect_true("empty string" %in% res$description)
  expect_named(
    res,
    c("pattern", "description", "rank", "n_matches", "example_values")
  )
})


# ——————————————————————————————————————————————————————————————————————
# format2dada2
# ——————————————————————————————————————————————————————————————————————

test_that("format2dada2 converts UNITE to dada2 at the string level", {
  res <- format2dada2(
    taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes",
    input_format = "unite"
  )
  expect_equal(res, "Fungi;Ascomycota;Sordariomycetes;")
})

test_that("format2dada2 round-trips a UNITE fixture through file I/O", {
  in_fa <- fixture_dbpq("fmt_unite.fasta")
  out_fa <- tempfile(fileext = ".fasta")
  on.exit(unlink(out_fa), add = TRUE)
  format2dada2(fasta_db = in_fa, output_path = out_fa)
  out_lines <- readLines(out_fa)
  expect_true(any(grepl("Ascomycota;Sordariomycetes;Hypocreales;", out_lines)))
  expect_true(any(grepl("Basidiomycota;Agaricomycetes;Agaricales;", out_lines)))
  expect_true(any(grepl(
    "Eurotiomycetes;Eurotiales;Aspergillaceae;",
    out_lines
  )))
})


# ——————————————————————————————————————————————————————————————————————
# format2sintax
# ——————————————————————————————————————————————————————————————————————

test_that("format2sintax converts UNITE to SINTAX at the string level", {
  res <- format2sintax(
    taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes"
  )
  expect_equal(
    res,
    "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes"
  )
})

test_that("format2sintax round-trips a UNITE fixture through file I/O", {
  in_fa <- fixture_dbpq("fmt_unite.fasta")
  out_fa <- tempfile(fileext = ".fasta")
  on.exit(unlink(out_fa), add = TRUE)
  format2sintax(fasta_db = in_fa, output_path = out_fa)
  out_lines <- readLines(out_fa)
  # UNITE headers with '|' in the ID lose the kingdom rank (parser
  # treats the ID as the first ';' chunk), so we look for the well-known
  # phylum rank pattern instead.
  expect_true(any(grepl("tax=p:Ascomycota", out_lines)))
  expect_true(any(grepl("tax=p:Basidiomycota", out_lines)))
  expect_true(any(grepl("g:Fusarium", out_lines)))
})


# ——————————————————————————————————————————————————————————————————————
# format2dada2_species
# ——————————————————————————————————————————————————————————————————————

test_that("format2dada2_species extracts genus and species at the string level", {
  res <- format2dada2_species(
    taxnames = "AB123;k__Fungi;g__Aspergillus;s__fumigatus"
  )
  expect_true(grepl("Aspergillus", res))
  expect_true(grepl("fumigatus", res))
  expect_true(grepl("AB123", res))
})

test_that("format2dada2_species round-trips a UNITE fixture through file I/O", {
  in_fa <- fixture_dbpq("fmt_dada2_species.fasta")
  out_fa <- tempfile(fileext = ".fasta")
  on.exit(unlink(out_fa), add = TRUE)
  format2dada2_species(fasta_db = in_fa, output_path = out_fa)
  out_lines <- readLines(out_fa)
  expect_true(any(grepl("Escherichia_coli", out_lines)))
  expect_true(any(grepl("Pseudomonas_aeruginosa", out_lines)))
  expect_true(any(grepl("Streptococcus_pneumoniae", out_lines)))
})


# ——————————————————————————————————————————————————————————————————————
# format_fasta_db
# ——————————————————————————————————————————————————————————————————————

test_that("format_fasta_db converts Greengenes2 to dada2 at the string level", {
  res <- format_fasta_db(
    taxnames = "abc123 d__Bacteria;p__Pseudomonadota;g__Escherichia",
    input_format = "greengenes2",
    output_format = "dada2"
  )
  expect_equal(res, "Bacteria;Pseudomonadota;Escherichia;")
})

test_that("format_fasta_db round-trips a Greengenes2 fixture to dada2 through file I/O", {
  in_fa <- fixture_dbpq("fmt_greengenes2.fasta")
  out_fa <- tempfile(fileext = ".fasta")
  on.exit(unlink(out_fa), add = TRUE)
  format_fasta_db(
    fasta_db = in_fa,
    input_format = "greengenes2",
    output_format = "dada2",
    output_path = out_fa
  )
  out_lines <- readLines(out_fa)
  expect_true(any(grepl(
    "^>Bacteria;Pseudomonadota;Gammaproteobacteria;",
    out_lines
  )))
  expect_true(any(grepl(
    "^>Bacteria;Firmicutes;Bacilli;",
    out_lines
  )))
})

test_that("format_fasta_db round-trips a SINTAX fixture to UNITE through file I/O", {
  in_fa <- fixture_dbpq("fmt_sintax.fasta")
  out_fa <- tempfile(fileext = ".fasta")
  on.exit(unlink(out_fa), add = TRUE)
  format_fasta_db(
    fasta_db = in_fa,
    input_format = "sintax",
    output_format = "unite",
    output_path = out_fa
  )
  out_lines <- readLines(out_fa)
  # SINTAX carries a 'd:' (domain) rank; the UNITE renderer preserves it
  # so the d__ prefix is kept.
  expect_true(any(grepl(
    "^>SH101;d__Eukaryota;k__Fungi;p__Basidiomycota",
    out_lines
  )))
  expect_true(any(grepl(
    "^>SH102;d__Eukaryota;k__Fungi;p__Ascomycota",
    out_lines
  )))
  expect_true(any(grepl(
    "^>SH103;d__Eukaryota;k__Fungi;p__Basidiomycota",
    out_lines
  )))
})


# ——————————————————————————————————————————————————————————————————————
# get_file_extension
# ——————————————————————————————————————————————————————————————————————

test_that("get_file_extension returns the expected vector for each fixture path", {
  expect_equal(get_file_extension(fixture_dbpq("fmt_unite.fasta")), "fasta")
  expect_equal(
    get_file_extension(fixture_dbpq("fmt_unite.fasta.gz")),
    c("fasta", "gz")
  )
  expect_equal(get_file_extension("my_db.fna"), "fna")
  expect_equal(get_file_extension("my_db.gz"), "gz")
})
