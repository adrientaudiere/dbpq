test_that("format2sintax converts standard taxonomy to SINTAX", {
  input <- "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes"
  result <- format2sintax(taxnames = input)
  expect_true(grepl("tax=k:", result))
  expect_true(grepl("p:", result))
  expect_true(grepl("c:", result))
})

test_that("format2sintax errors when both arguments provided", {
  expect_error(
    format2sintax(fasta_db = "file.fasta", taxnames = "name"),
    "either"
  )
})

test_that("format2sintax errors when no arguments provided", {
  expect_error(format2sintax(), "must specify")
})

test_that("format2dada2_species extracts genus and species", {
  input <- "AB123;k__Fungi;g__Aspergillus;s__fumigatus"
  result <- format2dada2_species(taxnames = input, from_sintax = FALSE)
  expect_true(grepl("Aspergillus", result))
  expect_true(grepl("fumigatus", result))
})
