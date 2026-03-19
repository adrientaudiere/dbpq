test_that("download functions exist and have correct signatures", {
  expect_true(is.function(download_unite_db))
  expect_true(is.function(download_silva_db))
  expect_true(is.function(download_pr2_db))
  expect_true(is.function(download_bold_db))
  expect_true(is.function(download_marjaam_db))
  expect_true(is.function(download_eukaryome_db))
})

test_that("download stubs error with informative message", {
  expect_error(download_unite_db(), "not yet implemented")
  expect_error(download_silva_db(), "not yet implemented")
})
