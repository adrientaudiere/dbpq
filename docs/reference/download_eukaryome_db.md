# Download the Eukaryome reference database

Downloads the Eukaryome database for eukaryotic organisms. Supports
multiple markers (SSU 18S, ITS, LSU 28S) and output formats (general
FASTA, dada2, mothur).

## Usage

``` r
download_eukaryome_db(dest_dir = ".", url = NULL, verbose = TRUE)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- url:

  (Character) Direct download URL for the Eukaryome file. Override if
  the URL has changed. If `NULL` (default), the function directs you to
  the Eukaryome download page.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly), or a message with download
instructions if no URL is provided.

## Details

Eukaryome does not provide a stable programmatic download API. Files are
available at <https://eukaryome.org/download/> in several formats:

- General FASTA: <https://eukaryome.org/generalfasta/>

- dada2 format: <https://eukaryome.org/dada2/>

- mothur format: <https://eukaryome.org/mothur/>

- SINTAX format: <https://eukaryome.org/sintax/>

- QIIME2 format: <https://eukaryome.org/qiime2/>

Visit one of these pages, copy the direct download link, and pass it via
the `url` parameter.

Please cite: Vasar M et al. (2024) Eukaryome: the rRNA gene reference
database for identification of all eukaryotes. Database.
[doi:10.1093/database/baae043](https://doi.org/10.1093/database/baae043)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download with a specific URL from the Eukaryome website
download_eukaryome_db(
  dest_dir = "databases",
  url = "https://eukaryome.org/files/eukaryome_v1.9_SSU_dada2.fasta.gz"
)
} # }
```
