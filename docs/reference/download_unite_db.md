# Download a UNITE reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the UNITE fungal ITS database for taxonomic assignment from
the UNITE DOI repository (PlutoF/Zenodo). Provides both "dynamic"
(including singletons) and "static" versions, for fungi or all
eukaryotes.

UNITE general FASTA releases use the `k__`/`p__` taxonomy format and are
compatible with dada2, VSEARCH, and other classifiers after reformatting
with
[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md)
or
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md).

## Usage

``` r
download_unite_db(
  dest_dir = ".",
  type = c("dynamic", "static"),
  taxon_group = c("fungi", "eukaryotes"),
  version = "10.0",
  taxonomic_format = c("default", "sintax"),
  doi = NULL,
  url = NULL,
  extract = FALSE,
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- type:

  (Character, default `"dynamic"`) One of `"dynamic"` or `"static"`.
  Dynamic files include singletons. Only used when
  `taxonomic_format = "default"`. Note: as of UNITE v10.0, separate
  static/dynamic archives are not available for `taxon_group = "fungi"`;
  both options download the same archive.

- taxon_group:

  (Character, default `"fungi"`) One of `"fungi"` or `"eukaryotes"`.

- version:

  (Character, default `"10.0"`) UNITE version. Use `"10.0"` for the 2024
  release.

- taxonomic_format:

  (Character, default `"default"`) One of `"default"` or `"sintax"`.
  When `"default"`, downloads the general FASTA release (`.tgz` archive
  with `k__`/`p__` taxonomy). When `"sintax"`, downloads a single FASTA
  file already formatted for VSEARCH SINTAX classification (with
  `tax=d:...` headers).

- doi:

  (Character) If provided, overrides version-based URL construction with
  a direct DOI download. Useful for older or alternative releases. Note
  that UNITE DOIs currently resolve to an HTML landing page rather than
  to the archive; prefer `url`.

- url:

  (Character) Direct download URL of a UNITE file, for example the S3
  link of a general FASTA release. Takes precedence over `version`,
  `type`, `taxon_group` and `doi`; the downloaded file keeps the
  basename of the URL. See Details to find the URL of a release.

- extract:

  (Logical, default `FALSE`) If `TRUE`, extract the downloaded
  general-release `.tgz` archive into `dest_dir`, delete the archive and
  return the path of the FASTA file that is not the `_dev` variant. Only
  valid for `.tgz` archives.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly).

## Details

When `taxonomic_format = "default"`: since UNITE v10.0, the `.tgz`
archive contains all clustering variants (dynamic, 97%, 99%) bundled
together. After downloading, extract the archive and select the
appropriate FASTA file.

When `taxonomic_format = "sintax"`: the downloaded `.gz` file is a
single FASTA with SINTAX-ready taxonomy headers. This file can be used
directly with `vsearch --sintax`.

The S3 download URLs use opaque UUIDs that change between releases. If
the automatic URL fails, visit <https://unite.ut.ee/repository.php> to
find the current DOI and pass it via the `doi` parameter, or download
manually.

To download a release that is not hard-coded (for example the 19.02.2025
releases), query the public PlutoF API with its DOI, e.g.
`https://api.plutof.ut.ee/v1/public/dois/?identifier=10.15156/BIO/3301232`,
and pass the `url` of the attached archive together with
`extract = TRUE`.

Please cite UNITE: Abarenkov K et al. (2024) UNITE general FASTA release
for Fungi. UNITE Community.
[doi:10.15156/BIO/2959336](https://doi.org/10.15156/BIO/2959336)

## See also

[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download UNITE v10.0 default (general FASTA archive) for fungi
download_unite_db(dest_dir = "databases")

# Download UNITE v10.0 SINTAX-formatted for fungi
download_unite_db(dest_dir = "databases", taxonomic_format = "sintax")

# Download for all eukaryotes in SINTAX format
download_unite_db(
  dest_dir = "databases",
  taxon_group = "eukaryotes",
  taxonomic_format = "sintax"
)

# UNITE 19.02.2025 general release for all eukaryotes, with
# singletons, from its direct URL, keeping only the non-dev FASTA
download_unite_db(
  dest_dir = "databases",
  url = paste0(
    "https://s3.hpc.ut.ee/plutof-public/original/",
    "b02db549-5f04-43fc-afb6-02888b594d10.tgz"
  ),
  extract = TRUE
)
} # }
```
