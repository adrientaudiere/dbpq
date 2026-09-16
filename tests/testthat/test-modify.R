test_that("filter_db errors without output", {
  expect_error(filter_db("file.fasta", "pattern"), "must specify an output")
})

its1f <- "CTTGGTCATTTAGAGGAAGTAA"
its2 <- "GCTGCGTTCTTCATCGATGC"
its2_rc <- "GCATCGATGAAGAACGCAGC"

cutadapt_cmd <- function(...) {
  fasta <- tempfile(fileext = ".fasta")
  writeLines(c(">r1", "ACGT"), fasta)
  cutadapt_rm_primers_db(
    fasta,
    output = "out.fasta",
    primer_fw = its1f,
    primer_rev = its2,
    cmd_is_run = FALSE,
    args_before_cutadapt = "",
    ...
  )
}

test_that("cutadapt_rm_primers_db reverse-complements primer_rev by default", {
  cmd <- cutadapt_cmd()
  expect_match(
    cmd,
    paste0("-a '", its1f, ";optional...", its2_rc, ";optional'"),
    fixed = TRUE
  )
  expect_match(cmd, "--discard-untrimmed", fixed = TRUE)
  expect_no_match(cmd, " -O ", fixed = TRUE)
  expect_match(
    cutadapt_cmd(rc_primer_rev = FALSE),
    paste0("...", its2, ";optional'"),
    fixed = TRUE
  )
})

test_that("cutadapt_rm_primers_db sets required primers, overlap and untrimmed output", {
  cmd <- cutadapt_cmd(
    primer_rev_required = TRUE,
    min_overlap = 20,
    discard_untrimmed = FALSE
  )
  expect_match(cmd, paste0(";optional...", its2_rc, ";required'"), fixed = TRUE)
  expect_match(cmd, " -O 20", fixed = TRUE)
  expect_no_match(cmd, "--discard-untrimmed", fixed = TRUE)
  expect_match(
    cutadapt_cmd(start_with_fw = TRUE),
    paste0("-a '^", its1f, ";required..."),
    fixed = TRUE
  )
})

test_that("cutadapt_rm_primers_db filters short sequences with min_length", {
  expect_no_match(cutadapt_cmd(), " -m ", fixed = TRUE)
  expect_match(cutadapt_cmd(min_length = 50), " -m 50", fixed = TRUE)
})

test_that("cutadapt_rm_primers_db errors without both primers", {
  fasta <- tempfile(fileext = ".fasta")
  writeLines(c(">r1", "ACGT"), fasta)
  expect_error(
    cutadapt_rm_primers_db(fasta, primer_fw = its1f, cmd_is_run = FALSE),
    "primer_rev"
  )
})

test_that("cutadapt_rm_primers_db trims forward-oriented references", {
  prelude <- eval(formals(cutadapt_rm_primers_db)$args_before_cutadapt)
  cutadapt_ok <- system2(
    "bash",
    c("-c", shQuote(paste0(prelude, "cutadapt --version"))),
    stdout = FALSE,
    stderr = FALSE
  ) ==
    0
  skip_if_not(cutadapt_ok, "cutadapt (cutadaptenv conda env) not available")

  insert <- paste(rep("ACGTTGACCATGGTACCAGT", 5), collapse = "")
  flank <- "TTTTTAAAAACCCCCGGGGG"
  fasta <- tempfile(fileext = ".fasta")
  writeLines(
    c(
      ">both",
      paste0(flank, its1f, insert, its2_rc, flank),
      ">rev_only",
      paste0(insert, its2_rc, flank),
      ">rev_partial_end",
      paste0(insert, substr(its2_rc, 1, 6)),
      ">none",
      insert
    ),
    fasta
  )

  kept_all <- tempfile(fileext = ".fasta")
  cutadapt_rm_primers_db(
    fasta,
    output = kept_all,
    primer_fw = its1f,
    primer_rev = its2,
    discard_untrimmed = FALSE,
    min_overlap = 20,
    verbose = FALSE
  )
  res <- Biostrings::readDNAStringSet(kept_all)
  expect_equal(names(res), c("both", "rev_only", "rev_partial_end", "none"))
  expect_equal(as.character(res[["both"]]), insert)
  expect_equal(as.character(res[["rev_only"]]), insert)
  expect_equal(length(res[["rev_partial_end"]]), nchar(insert) + 6)

  rev_site <- tempfile(fileext = ".fasta")
  cutadapt_rm_primers_db(
    fasta,
    output = rev_site,
    primer_fw = its1f,
    primer_rev = its2,
    primer_rev_required = TRUE,
    min_overlap = 20,
    verbose = FALSE
  )
  expect_equal(
    names(Biostrings::readDNAStringSet(rev_site)),
    c("both", "rev_only")
  )
})
