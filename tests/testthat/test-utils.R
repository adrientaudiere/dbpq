test_that("get_file_extension works with single extension", {
  expect_equal(get_file_extension("database.fasta"), "fasta")
})

test_that("get_file_extension works with double extension", {
  expect_equal(get_file_extension("database.fasta.gz"), c("fasta", "gz"))
})

test_that("get_file_extension errors without extension", {
  expect_error(get_file_extension("database"), "No file extension found in")
})
