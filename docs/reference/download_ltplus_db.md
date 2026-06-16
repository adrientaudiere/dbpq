# Download the LTPlus reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the LTPlus 16S rRNA gene reference FASTA for Bacteria and
Archaea. LTPlus extends the All-Species Living Tree Project (LTP)
type-strain collection with the best-quality non-type sequences selected
from the SILVA non-redundant and GTDB databases, plus the
highest-quality 16S sequences deposited at NCBI between 2019 and 2025.
Sequences are clustered non-redundantly at a 98.7% identity threshold,
yielding a compact database that covers most of the known prokaryotic
genealogical diversity.

## Usage

``` r
download_ltplus_db(
  dest_dir = ".",
  url = "https://biocom.uib.es/opucheck-backend/api/releases/02_26_06",
  tax_format = c("dada2", "sintax", "none"),
  csv_url = "https://biocom.uib.es/opucheck-backend/api/releases/02_26_02",
  to_dna = TRUE,
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded FASTA
  file.

- url:

  (Character) Direct download URL for the LTPlus FASTA. Defaults to the
  February 2026 release served by the Marine Microbiology Group (IMEDEA,
  UIB-CSIC). Pass a different release URL to download another version
  (see Details).

- tax_format:

  (Character, default `"dada2"`) Taxonomy format to write into the FASTA
  headers, so the file can feed
  [`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html).
  One of:

  - `"dada2"`: unprefixed, semicolon-delimited ranks
    (`>Bacteria;Pseudomonadota;...;`).

  - `"sintax"`: `>ID;tax=d:Bacteria,p:Pseudomonadota,...`.

  - `"none"`: keep the original accession-only headers. Taxonomy is read
    from the companion CSV (see `csv_url`).

- csv_url:

  (Character) URL of the LTPlus metadata CSV that maps each sequence
  accession to its full taxonomy. Defaults to the CSV of the February
  2026 release. Only used when `tax_format != "none"`.

- to_dna:

  (Logical, default `TRUE`) Convert the downloaded RNA FASTA to DNA
  (transcribe `U` to `T`) and rewrite it as a standard FASTA. Set to
  `FALSE` to keep the original RNA file unchanged. Requires the
  Biostrings package.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly).

## Details

The file is the LTPlus 16S FASTA exported from the underlying curated
alignment with gap columns removed ("compressed"), so the sequences are
**unaligned** and vary in length (~140 MB total). It is served directly
(no registration) from the LTP release backend; the file name is taken
from the server's `Content-Disposition` header when available (e.g.
`ltplus_10_02_2026_compressed.fasta`).

The released sequences are in the **RNA alphabet** (`U` rather than `T`)
and the sequence lines contain whitespace. With `to_dna = TRUE`
(default) the function transcribes `U` to `T` and rewrites a clean,
whitespace-free DNA FASTA in place, ready for DNA-based classifiers such
as dada2 or VSEARCH. With `to_dna = FALSE` the original RNA file is kept
as-is.

The released FASTA headers carry only an accession (e.g. `>LAJZ3046`);
the taxonomy lives in a companion CSV. With `tax_format = "dada2"`
(default) or `"sintax"` the function downloads that CSV, maps each
accession to its full LTPlus lineage, and rewrites the headers with
taxonomy so the file is ready for
[`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html).
Use `tax_format = "none"` to keep the accession-only headers.

The default `url` points to the current release file. To list available
releases and files, see the Downloads section of
<https://bioinfo.uib.es/ltp/> or query
<https://biocom.uib.es/opucheck-backend/api/releases>; each file has an
id appended to `.../api/releases/` to form its download URL. The ARB
database, CSV and Newick tree files are also available there.

Please cite: Rosselló-Móra R et al. (2026) A pipeline for improved 16S
rRNA gene-based phylogeny and diversity analyses of Bacteria and
Archaea. Research Square.
[doi:10.21203/rs.3.rs-9370187/v1](https://doi.org/10.21203/rs.3.rs-9370187/v1)

## See also

[`download_silva_db()`](https://adrientaudiere.github.io/dbpq/reference/download_silva_db.md),
[`download_greengenes2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_greengenes2_db.md),
[`download_ksgp_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ksgp_db.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download the current LTPlus 16S FASTA (DNA, dada2 taxonomy headers)
download_ltplus_db(dest_dir = "databases")

# SINTAX-formatted headers instead
download_ltplus_db(dest_dir = "databases", tax_format = "sintax")

# Keep the original RNA, accession-only FASTA without conversion
download_ltplus_db(dest_dir = "databases", to_dna = FALSE, tax_format = "none")
} # }
```
