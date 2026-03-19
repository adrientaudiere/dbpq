test_that("format2sintax converts UNITE to SINTAX", {
  result <- format2sintax(
    taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes"
  )
  expect_true(grepl("tax=k:", result))
  expect_true(grepl("p:", result))
  expect_true(grepl("c:", result))
  expect_equal(result, "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes")
})

test_that("format2sintax converts Greengenes2 to SINTAX", {
  result <- format2sintax(taxnames = "abc123 d__Bacteria;p__Pseudomonadota")
  expect_equal(result, "abc123;tax=d:Bacteria,p:Pseudomonadota")
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

test_that("format2dada2 converts SINTAX to dada2", {
  result <- format2dada2(
    taxnames = "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes"
  )
  expect_equal(result, "Fungi;Ascomycota;Sordariomycetes;")
})

test_that("format2dada2 converts UNITE to dada2", {
  result <- format2dada2(
    taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes",
    input_format = "unite"
  )
  expect_equal(result, "Fungi;Ascomycota;Sordariomycetes;")
})

test_that("format2dada2_species extracts genus and species from UNITE", {
  result <- format2dada2_species(
    taxnames = "AB123;k__Fungi;g__Aspergillus;s__fumigatus"
  )
  expect_true(grepl("Aspergillus", result))
  expect_true(grepl("fumigatus", result))
  expect_true(grepl("AB123", result))
})

test_that("format2dada2_species extracts genus and species from SINTAX", {
  result <- format2dada2_species(
    taxnames = "AB123;tax=k:Fungi,g:Aspergillus,s:fumigatus",
    input_format = "sintax"
  )
  expect_true(grepl("Aspergillus", result))
  expect_true(grepl("fumigatus", result))
})

test_that("format_fasta_db converts UNITE to SINTAX", {
  result <- format_fasta_db(
    taxnames = "AB123;k__Fungi;p__Ascomycota",
    output_format = "sintax"
  )
  expect_equal(result, "AB123;tax=k:Fungi,p:Ascomycota")
})

test_that("format_fasta_db converts SINTAX to UNITE", {
  result <- format_fasta_db(
    taxnames = "AB123;tax=k:Fungi,p:Ascomycota",
    output_format = "unite"
  )
  expect_equal(result, "AB123;k__Fungi;p__Ascomycota")
})

test_that("format_fasta_db converts Greengenes2 to SINTAX", {
  result <- format_fasta_db(
    taxnames = "abc123 d__Bacteria;p__Pseudomonadota",
    output_format = "sintax"
  )
  expect_equal(result, "abc123;tax=d:Bacteria,p:Pseudomonadota")
})

test_that("format_fasta_db converts Greengenes2 to dada2", {
  result <- format_fasta_db(
    taxnames = "abc123 d__Bacteria;p__Pseudomonadota;g__Escherichia",
    output_format = "dada2"
  )
  expect_equal(result, "Bacteria;Pseudomonadota;Escherichia;")
})

test_that("format_fasta_db converts SINTAX to Greengenes2", {
  result <- format_fasta_db(
    taxnames = "abc123;tax=d:Bacteria,p:Pseudomonadota",
    output_format = "greengenes2"
  )
  expect_equal(result, "abc123 d__Bacteria;p__Pseudomonadota")
})

test_that("format_fasta_db errors when both arguments provided", {
  expect_error(
    format_fasta_db(
      fasta_db = "file.fasta",
      taxnames = "name",
      output_format = "sintax"
    ),
    "either"
  )
})

test_that("format_fasta_db errors on unknown auto-detected format", {
  expect_error(
    format_fasta_db(
      taxnames = "Bacteria;Proteobacteria",
      output_format = "sintax"
    ),
    "auto-detect"
  )
})
