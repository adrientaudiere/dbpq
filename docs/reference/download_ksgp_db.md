# Download the KSGP or GTDB+ reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the KSGP (Karst, Silva, GTDB, and PR2) reference database for
SSU rRNA taxonomic assignment, particularly optimized for Archaea
communities. KSGP combines near full-length rRNA sequences from Karst et
al. 2018, re-annotated SILVA prokaryote SSU sequences, cleaned GTDB 16S
sequences, PR2 eukaryote 18S sequences, and MIDORI2 mitochondrial
sequences. Taxonomy is based on GTDB, providing phylogenetically
consistent classification.

Also provides access to the GTDB+ and GTDB_cleaned databases built as
intermediate steps during KSGP construction.

Three annotation variants are available for `database = "KSGP"` and
`file_type = "tax"`:

- `"sintax"` (default): SINTAX-based taxonomic assignments (KSGP Sintax
  in the paper). Available for all versions.

- `"lca"`: Conservative lowest common ancestor assignments (KSGP LCA).
  Only available for version `"3.1"`.

- `"ksgp_plus"`: Similarity-clustered putative taxa (KSGP+). Only
  available for version `"3.1"`.

## Usage

``` r
download_ksgp_db(
  dest_dir = ".",
  database = c("KSGP", "GTDB_plus", "GTDB_cleaned"),
  file_type = c("fasta", "tax", "archive"),
  annotation = c("lca", "sintax", "ksgp_plus"),
  tax_format = c("dada2", "sintax", "none"),
  version = "3.1",
  verbose = TRUE,
  timeout = Inf
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- database:

  (Character, default `"KSGP"`) One of:

  - `"KSGP"`: Full KSGP SSU database (Archaea + Bacteria + Eukaryota).

  - `"GTDB_plus"`: Cleaned GTDB 16S sequences with PR2 and MIDORI2.

  - `"GTDB_cleaned"`: Cleaned GTDB 16S sequences only (no eukaryote
    supplement).

- file_type:

  (Character, default `"fasta"`) One of:

  - `"fasta"`: FASTA file with SSU sequences.

  - `"tax"`: Taxonomy file (`.tax`) with taxonomic annotations.

  - `"archive"`: Complete `.tar.gz` archive (all KSGP files, all
    annotation variants). Only available for `database = "KSGP"`.

- annotation:

  (Character, default `"lca"`) Taxonomic annotation method. One of
  `"lca"`, `"sintax"`, or `"ksgp_plus"`. Used to pick the matching
  `.tax` file when `file_type = "tax"`, and to pick the taxonomy merged
  into the FASTA headers when `file_type = "fasta"` and
  `tax_format != "none"`. The `lca` annotation has the broadest sequence
  coverage and is the default for a fully-annotated KSGP FASTA. Only
  `"sintax"` is available for version `"1.0"`.

- tax_format:

  (Character, default `"dada2"`) When `file_type = "fasta"`, also
  download the companion `.tax` file and merge its taxonomy into the
  FASTA headers (matched by sequence ID), so the file feeds
  [`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html).
  One of `"dada2"`, `"sintax"`, or `"none"` (keep accession-only
  headers). Sequences whose ID is absent from the `.tax` (e.g. the
  SILVA-derived portion) keep accession-only headers. Ignored for
  `file_type = "tax"` / `"archive"`.

- version:

  (Character, default `"3.1"`) KSGP version. Known versions: `"3.1"`
  (2025, recommended) and `"1.0"`.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

- timeout:

  (Numeric, default `Inf`) Timeout in seconds for each HTTP request. The
  default disables R's 60-second timeout so the multi-hundred-MB to
  multi-GB downloads (KSGP FASTA, the v3.1 archive) can complete. Set to
  a positive number of seconds to restore a strict timeout.

## Value

The path to the downloaded file (invisibly).

## Details

When `file_type = "fasta"`, the function downloads the matching
`KSGP_v<version>.tar.gz` archive (one HTTP request) and extracts the
FASTA — and, when `tax_format != "none"`, the chosen `.tax` file — to
`dest_dir`, then removes the archive. The archive is roughly 3.5x
smaller than the raw FASTA (e.g. ~686 MB vs ~2.4 GB for v3.1), so this
is both faster and lighter on the server than two separate requests. The
KSGP FASTA and taxonomy files are otherwise separate downloads.

With `tax_format = "sintax"` (or `"dada2"`), the taxonomy is merged into
the FASTA headers (one sequence ID per row, matched against the `.tax`
file) and the `.tax` file is removed, so the result is a single FASTA
ready for VSEARCH/dada2 — the original prefix letters from the `.tax`
are preserved in the SINTAX output (a KSGP line starting with
`k__Bacteria;` becomes `>ID;tax=k:Bacteria,...`, not `d:Bacteria,...`).
To use KSGP for taxonomic assignment:

- With VSEARCH SINTAX: download the FASTA (`file_type = "fasta"`,
  `tax_format = "sintax"`).

- With dada2: download the FASTA (`file_type = "fasta"`,
  `tax_format = "dada2"`).

- With LotuS2: the KSGP database is integrated directly.

- For a complete set of all files: use `file_type = "archive"`.

KSGP substantially improves Archaea annotation over SILVA and
Greengenes2: Class and Order assignments increase by 2.7x and 4.2x
respectively.

Please cite: Grant A et al. (2025) KSGP 3.1: improved taxonomic
annotation of Archaea communities using LotuS2, the genome taxonomy
database and RNAseq data. ISME Communications 5(1): ycaf094.
[doi:10.1093/ismeco/ycaf094](https://doi.org/10.1093/ismeco/ycaf094)

## See also

[`download_silva_db()`](https://adrientaudiere.github.io/dbpq/reference/download_silva_db.md),
[`download_pr2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_pr2_db.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download KSGP v3.1 FASTA
download_ksgp_db(dest_dir = "databases")

# Download KSGP v3.1 LCA taxonomy file
download_ksgp_db(
  dest_dir = "databases",
  file_type = "tax",
  annotation = "lca"
)

# Download KSGP+ taxonomy file
download_ksgp_db(
  dest_dir = "databases",
  file_type = "tax",
  annotation = "ksgp_plus"
)

# Download the complete KSGP archive (all annotation variants)
download_ksgp_db(dest_dir = "databases", file_type = "archive")

# Download GTDB+ (cleaned GTDB + PR2 + MIDORI2)
download_ksgp_db(dest_dir = "databases", database = "GTDB_plus")
} # }
```
