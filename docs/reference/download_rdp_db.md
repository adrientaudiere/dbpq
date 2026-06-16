# Download an RDP reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the Ribosomal Database Project (RDP) 16S rRNA database. By
default, downloads the dada2-formatted training sets from Zenodo
(maintained by Benjamin Callahan).

## Usage

``` r
download_rdp_db(
  dest_dir = ".",
  trainset = "19",
  format = c("dada2", "dada2_species"),
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- trainset:

  (Character, default `"19"`) RDP trainset version number.

- format:

  (Character, default `"dada2"`) One of:

  - `"dada2"`: training set for
    [`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html).

  - `"dada2_species"`: species assignment file for
    [`dada2::addSpecies()`](https://rdrr.io/pkg/dada2/man/addSpecies.html).

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly).

## Details

The dada2-formatted files are maintained by Benjamin Callahan on Zenodo.
See <https://benjjneb.github.io/dada2/training.html> for details.

Please cite: Cole JR et al. (2014) Ribosomal Database Project: data and
tools for high throughput rRNA analysis. Nucleic Acids Research
42:D633-D642.
[doi:10.1093/nar/gkt1244](https://doi.org/10.1093/nar/gkt1244)

## See also

[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`download_silva_db()`](https://adrientaudiere.github.io/dbpq/reference/download_silva_db.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download RDP trainset 19 for assignTaxonomy()
download_rdp_db(dest_dir = "databases")

# Download species assignment file
download_rdp_db(dest_dir = "databases", format = "dada2_species")
} # }
```
