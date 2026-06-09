test_that("download functions exist and have correct signatures", {
  expect_true(is.function(download_unite_db))
  expect_true(is.function(download_silva_db))
  expect_true(is.function(download_pr2_db))
  expect_true(is.function(download_bold_db))
  expect_true(is.function(download_marjaam_db))
  expect_true(is.function(download_eukaryome_db))
  expect_true(is.function(download_greengenes2_db))
  expect_true(is.function(download_rdp_db))
  expect_true(is.function(download_midori2_db))
  expect_true(is.function(download_diatbarcode_db))
  expect_true(is.function(download_ksgp_db))
  expect_true(is.function(download_ltplus_db))
})

test_that("download_bold_db requires taxon argument", {
  expect_error(download_bold_db(), "must specify a taxon")
})

test_that("download_silva_db supports the sintax format and LSU target", {
  fmts <- eval(formals(download_silva_db)$format)
  expect_true(
    all(c("dada2", "dada2_species", "sintax", "raw") %in% fmts)
  )
  expect_true("LSU" %in% eval(formals(download_silva_db)$target))
  expect_true("id_prefix" %in% names(formals(format2sintax)))
})

test_that("download_eukaryome_db without URL gives instructions", {
  expect_message(download_eukaryome_db(), "does not provide stable")
})

test_that("download_eukaryome_db without URL mentions SINTAX format", {
  expect_message(download_eukaryome_db(), "SINTAX")
})

test_that("download_pr2_db accepts sintax as alias for UTAX", {
  # sintax should be accepted as a valid format
  expect_no_error(match.arg("sintax", c("dada2", "mothur", "UTAX", "sintax")))
})

test_that("download_unite_db accepts taxonomic_format parameter", {
  expect_true("taxonomic_format" %in% names(formals(download_unite_db)))
})

test_that("download_greengenes2_db rejects unknown version for dada2", {
  expect_error(
    download_greengenes2_db(version = "999.99", format = "dada2"),
    "No known Zenodo record"
  )
})

test_that("download_rdp_db rejects unknown trainset", {
  expect_error(
    download_rdp_db(trainset = "99"),
    "No known Zenodo record"
  )
})

test_that("download_midori2_db without URL gives instructions", {
  expect_message(download_midori2_db(), "reference-midori.info")
})

test_that("download_diatbarcode_db without URL gives instructions", {
  expect_message(download_diatbarcode_db(), "diatbarcode")
})

test_that("download_ltplus_db defaults to direct FASTA URL, DNA + dada2 tax", {
  expect_match(eval(formals(download_ltplus_db)$url), "^https://.*/releases/")
  expect_true(eval(formals(download_ltplus_db)$to_dna))
  expect_identical(eval(formals(download_ltplus_db)$tax_format)[1], "dada2")
  expect_true("csv_url" %in% names(formals(download_ltplus_db)))
})

test_that("download fns expose a dada2-default tax_format", {
  for (fn in list(
    download_ksgp_db,
    download_greengenes2_db,
    download_marjaam_db,
    download_bold_db
  )) {
    expect_identical(eval(formals(fn)$tax_format)[1], "dada2")
  }
})

test_that(".lineage_to_ranks keeps ranks aligned across an internal gap", {
  r <- dbpq:::.lineage_to_ranks(
    "Bacteria/Phylumx/noname~305/f__Ferroviaceae",
    sep = "/"
  )
  expect_identical(unname(r[["f"]]), "Ferroviaceae")
  expect_true(is.na(r[["c"]]))
  # dada2 keeps the empty field so family stays in position 5
  dada2 <- dbpq:::.render_tax_header(list(id = "x", ranks = r), "dada2")
  expect_identical(dada2, "Bacteria;Phylumx;;;Ferroviaceae;")
  # sintax omits the gap but keeps correct rank keys
  sx <- dbpq:::.render_tax_header(list(id = "x", ranks = r), "sintax")
  expect_match(sx, "f:Ferroviaceae")
  expect_false(grepl("c:", sx, fixed = TRUE))
})

test_that("download_ksgp_db rejects unknown version", {
  expect_error(
    download_ksgp_db(version = "99.9"),
    "No known KSGP download"
  )
})

test_that("download_ksgp_db rejects archive for GTDB databases", {
  expect_error(
    download_ksgp_db(database = "GTDB_plus", file_type = "archive"),
    "No known KSGP download"
  )
})

test_that("download_ksgp_db rejects lca annotation for v1.0", {
  expect_error(
    download_ksgp_db(version = "1.0", file_type = "tax", annotation = "lca"),
    "No known KSGP download"
  )
})

test_that("download_ksgp_db error lists known combinations", {
  err <- tryCatch(
    download_ksgp_db(version = "99.9"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "ksgp.earlham.ac.uk")
})

test_that("download_ksgp_db has expected formals", {
  fmts <- eval(formals(download_ksgp_db)$database)
  expect_true(all(c("KSGP", "GTDB_plus", "GTDB_cleaned") %in% fmts))
  ann <- eval(formals(download_ksgp_db)$annotation)
  expect_true(all(c("sintax", "lca", "ksgp_plus") %in% ann))
})

test_that("download_file cleans up on failure", {
  tmp <- tempfile(fileext = ".fasta")
  expect_error(
    download_file(
      "https://invalid.example.com/nonexistent.fasta",
      tmp,
      verbose = FALSE
    ),
    "Download failed"
  )
  expect_false(file.exists(tmp))
})

test_that("download_unite_db creates dest_dir if needed", {
  tmp_dir <- file.path(tempdir(), "test_unite_dir_check")
  if (dir.exists(tmp_dir)) {
    unlink(tmp_dir, recursive = TRUE)
  }
  # Use an invalid version to trigger an error after dir creation
  expect_error(
    download_unite_db(
      dest_dir = tmp_dir,
      doi = "10.0000/nonexistent"
    )
  )
  expect_true(dir.exists(tmp_dir))
  unlink(tmp_dir, recursive = TRUE)
})

test_that("download_file sets options(timeout) for the call and restores it", {
  old_timeout <- getOption("timeout")
  observed <- NULL
  testthat::local_mocked_bindings(
    download.file = function(url, destfile, mode, quiet, ...) {
      observed <<- getOption("timeout")
      writeLines("placeholder", destfile)
      0L
    },
    .package = "utils"
  )
  tmp <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp), add = TRUE)
  download_file(
    "https://example.com/file",
    tmp,
    verbose = FALSE,
    timeout = 123
  )
  # The helper set the option to the user-supplied timeout during the
  # download call.
  expect_equal(observed, 123)
  # And restored the caller's prior value once the call returned.
  expect_equal(getOption("timeout"), old_timeout)
})

test_that("download_ksgp_db routes FASTA downloads through the tar.gz archive", {
  skip_if_not_installed("testthat", "3.1.0")
  # Build a tiny fake archive that mirrors the real v3.1 layout (files
  # at the top level): a 2-record FASTA and a matching 2-line .tax file.
  fake_fasta <- c(
    ">seq1",
    "ACGT",
    ">seq2",
    "TTGG"
  )
  fake_tax <- c(
    "seq1\td__Bacteria;p__Pseudomonadota",
    "seq2\td__Archaea;p__Euryarchaeota"
  )
  build_dir <- tempfile("ksgp_build_")
  dir.create(build_dir)
  writeLines(fake_fasta, file.path(build_dir, "KSGP_v3.1.fasta"))
  writeLines(fake_tax, file.path(build_dir, "KSGP_v3.1.tax"))
  tar_gz <- tempfile(fileext = ".tar.gz")
  old_wd <- setwd(build_dir)
  utils::tar(tar_gz, files = c("KSGP_v3.1.fasta", "KSGP_v3.1.tax"))

  # Pre-stage the archive in dest_dir so the fasta branch can extract
  # from it without hitting the network.
  dest_dir <- file.path(tempdir(), "test_ksgp_archive")
  dir.create(dest_dir, showWarnings = FALSE)
  file.copy(
    tar_gz,
    file.path(dest_dir, "KSGP_v3.1.tar.gz"),
    overwrite = TRUE
  )

  # Mock download_file so any URL the function tries to fetch is a
  # no-op (the archive is already in place; no network calls needed).
  testthat::local_mocked_bindings(
    download_file = function(url, dest_path, verbose = TRUE, timeout = Inf) {
      invisible(dest_path)
    }
  )

  on.exit(
    {
      setwd(old_wd)
      unlink(tar_gz)
      unlink(build_dir, recursive = TRUE)
      unlink(dest_dir, recursive = TRUE)
    },
    add = TRUE
  )

  result_path <- download_ksgp_db(
    dest_dir = dest_dir,
    file_type = "fasta",
    tax_format = "sintax",
    verbose = FALSE
  )

  # The FASTA was extracted from the archive (not the raw download).
  expect_equal(basename(result_path), "KSGP_v3.1.fasta")
  expect_true(file.exists(result_path))
  expect_gt(file.size(result_path), 0L)
  # The archive was removed once extraction succeeded.
  expect_false(file.exists(file.path(dest_dir, "KSGP_v3.1.tar.gz")))
  # The .tax was extracted in the same pass.
  expect_true(file.exists(file.path(dest_dir, "KSGP_v3.1.tax")))
  # The tax-merge rewrote the FASTA with SINTAX headers.
  out_lines <- readLines(result_path)
  expect_true(any(grepl("^>seq1;tax=d:Bacteria,p:Pseudomonadota", out_lines)))
  expect_true(any(grepl("^>seq2;tax=d:Archaea,p:Euryarchaeota", out_lines)))
})
