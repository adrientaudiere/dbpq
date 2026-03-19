test_that("download functions exist and have correct signatures", {
  expect_true(is.function(download_unite_db))
  expect_true(is.function(download_silva_db))
  expect_true(is.function(download_pr2_db))
  expect_true(is.function(download_bold_db))
  expect_true(is.function(download_marjaam_db))
  expect_true(is.function(download_eukaryome_db))
})

test_that("download_bold_db requires taxon argument", {
  expect_error(download_bold_db(), "must specify a taxon")
})

test_that("download_silva_db rejects LSU with dada2 format", {
  expect_error(
    download_silva_db(target = "LSU", format = "dada2"),
    "only available for SSU"
  )
})

test_that("download_silva_db rejects unknown version for dada2", {
  expect_error(
    download_silva_db(version = "999.0", format = "dada2"),
    "No known Zenodo record"
  )
})

test_that("download_eukaryome_db without URL gives instructions", {
  expect_message(download_eukaryome_db(), "does not provide stable")
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
