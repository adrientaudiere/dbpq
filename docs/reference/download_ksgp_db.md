# Download the KSGP or GTDB+ reference database

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
  annotation = c("sintax", "lca", "ksgp_plus"),
  tax_format = c("dada2", "sintax", "none"),
  version = "3.1",
  verbose = TRUE
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

  (Character, default `"sintax"`) Taxonomic annotation method. One of
  `"sintax"`, `"lca"`, or `"ksgp_plus"`. Only applies when
  `database = "KSGP"` and `file_type = "tax"`. Only `"sintax"` is
  available for version `"1.0"`.

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

## Value

The path to the downloaded file (invisibly).

## Details

The KSGP FASTA and taxonomy files are separate downloads. To use KSGP
for taxonomic assignment:

- With VSEARCH SINTAX: download both the FASTA (`file_type = "fasta"`)
  and the SINTAX taxonomy (`file_type = "tax"`,
  `annotation = "sintax"`).

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
