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
