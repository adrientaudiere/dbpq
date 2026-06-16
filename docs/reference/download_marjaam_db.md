# Download the MaarjAM reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the MaarjAM database of arbuscular mycorrhizal fungi (AMF)
virtual taxa (VT) sequences, maintained at the University of Tartu. The
QIIME-formatted release (a zip bundling a FASTA and a taxonomy table) is
used so that the resulting FASTA carries taxonomy in its headers, ready
for
[`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html).

## Usage

``` r
download_marjaam_db(
  dest_dir = ".",
  dataset = c("SSU", "SSU_TYPE", "LSU", "full_ITS", "onlyITS"),
  tax_format = c("dada2", "sintax", "none"),
  url = NULL,
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- dataset:

  (Character, default `"SSU"`) Which MaarjAM marker release to download.
  One of `"SSU"`, `"SSU_TYPE"`, `"LSU"`, `"full_ITS"`, `"onlyITS"`.

- tax_format:

  (Character, default `"dada2"`) Taxonomy format written into the FASTA
  headers. One of `"dada2"`, `"sintax"`, or `"none"` (keep the QIIME
  `accession_VTX...` headers without taxonomy).

- url:

  (Character) Direct download URL for the MaarjAM QIIME zip. If `NULL`
  (default), it is built from `dataset`. Override if the URL has
  changed.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded FASTA file (invisibly).

## Details

The download links are listed at
<https://maarjam.ut.ee/?action=bDownload>. The QIIME zip contains
`*.qiime.fasta` and `*.qiime.txt` (a tab-separated
`id k__Fungi;p__...;s__VTX...` table); taxonomy is merged into the FASTA
headers by matching sequence IDs.

Please cite: Opik M et al. (2010) The online database MaarjAM reveals
global and ecosystemic distribution patterns in arbuscular mycorrhizal
fungi (Glomeromycota). New Phytologist 188:223-241.
[doi:10.1111/j.1469-8137.2010.03334.x](https://doi.org/10.1111/j.1469-8137.2010.03334.x)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# SSU (18S) AMF database with dada2 taxonomy headers
download_marjaam_db(dest_dir = "databases")

# SINTAX-formatted headers
download_marjaam_db(dest_dir = "databases", tax_format = "sintax")
} # }
```
