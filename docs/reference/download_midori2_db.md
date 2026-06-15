# Download a MIDORI2 reference database

Downloads the MIDORI2 reference database for eukaryotic mitochondrial
genes (COI, 12S, 16S, Cytb, etc.). MIDORI2 provides pre-formatted FASTA
files for multiple classifiers (dada2, SINTAX, RDP, BLAST).

## Usage

``` r
download_midori2_db(
  dest_dir = ".",
  gene = "CO1",
  format = c("dada2", "dada2_species", "SINTAX", "RDP", "BLAST"),
  seq_type = c("UNIQ", "LONGEST"),
  url = NULL,
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- gene:

  (Character, default `"CO1"`) Mitochondrial gene marker. Common values:
  `"CO1"`, `"srRNA"` (12S), `"lrRNA"` (16S), `"Cytb"`.

- format:

  (Character, default `"dada2"`) One of `"dada2"`, `"dada2_species"`,
  `"SINTAX"`, `"RDP"`, or `"BLAST"`.

- seq_type:

  (Character, default `"UNIQ"`) One of `"UNIQ"` (all unique haplotypes
  per species) or `"LONGEST"` (single longest sequence per species).

- url:

  (Character) Direct download URL. If `NULL` (default), the function
  provides instructions and the download page URL.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly), or a message with download
instructions if no URL is provided.

## Details

MIDORI2 download URLs include a date-stamped directory path that changes
with each GenBank release, making fully programmatic access fragile.
Visit <https://www.reference-midori.info/download.php> to find the
current download URL for your desired gene and format, then pass it via
the `url` parameter.

Files are typically named following this pattern:
`MIDORI2_{TYPE}_NUC_SP_GB{VERSION}_{GENE}_{FORMAT}.fasta.gz`

Please cite: Leray M et al. (2022) MIDORI2: A collection of quality
controlled, preformatted, and regularly updated reference databases for
taxonomic assignment of eukaryotic mitochondrial sequences.
Environmental DNA 4:894-907.
[doi:10.1002/edn3.303](https://doi.org/10.1002/edn3.303)

## See also

[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md),
[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Get instructions for downloading MIDORI2
download_midori2_db()

# Download with a specific URL
download_midori2_db(
  dest_dir = "databases",
  url = "https://reference-midori.info/download/Databases/..."
)
} # }
```
