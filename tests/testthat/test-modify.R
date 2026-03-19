test_that("filter_db errors without output", {
  expect_error(filter_db("file.fasta", "pattern"), "must specify an output")
})
