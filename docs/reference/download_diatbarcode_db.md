# Download a Diat.barcode reference database

Downloads the Diat.barcode reference database for diatom rbcL barcoding.
This is a curated database for diatom identification using the rbcL
marker gene. The recommended access method is through the
[diatbarcode](https://github.com/fkeck/diatbarcode) R package, which
provides additional tools for working with the database.

## Usage

``` r
download_diatbarcode_db(
  dest_dir = ".",
  format = c("dada2", "dada2_species"),
  url = NULL,
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- format:

  (Character, default `"dada2"`) One of `"dada2"` or `"dada2_species"`.
  Uses dada2-formatted files from the INRAE Dataverse.

- url:

  (Character) Direct download URL. If `NULL` (default), the function
  provides instructions for using the `diatbarcode` R package.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly), or a message with download
instructions if no URL is provided.

## Details

The Diat.barcode database is maintained by INRAE and hosted on Recherche
Data Gouv. For more advanced access (metadata, full taxonomy tables,
custom queries), consider using the
[diatbarcode](https://github.com/fkeck/diatbarcode) R package directly:

    diatbarcode::download_diatbarcode(
      path = "databases",
      flavor = "rbcl312_dada2_tax"
    )

Please cite: Rimet F et al. (2019) Diat.barcode, an open-access curated
barcode library for diatoms. Scientific Reports 9:15116.
[doi:10.1038/s41598-019-51500-6](https://doi.org/10.1038/s41598-019-51500-6)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
download_diatbarcode_db(dest_dir = "databases")
} # }
```
