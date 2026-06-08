# Download sequences from BOLD Systems

Downloads reference sequences from BOLD Systems (Barcode of Life Data)
for a given taxonomic group. Unlike other databases, BOLD does not
provide a single pre-built reference FASTA — sequences are queried by
taxon via the BOLD API.

## Usage

``` r
download_bold_db(
  dest_dir = ".",
  taxon = NULL,
  marker = "COI-5P",
  tax_format = c("dada2", "sintax", "none"),
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- taxon:

  (Character, required) Taxonomic name to query (e.g., `"Fungi"`,
  `"Arthropoda"`, `"Mammalia"`).

- marker:

  (Character, default `"COI-5P"`) The barcode marker. Common values:
  `"COI-5P"`, `"ITS"`, `"matK"`, `"rbcL"`.

- tax_format:

  (Character, default `"dada2"`) Taxonomy format written into the FASTA
  headers, so the file can feed
  [`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html).
  One of:

  - `"dada2"`: unprefixed, positional ranks
    (`>Phylum;Class;Order;Family;Genus;Species;`).

  - `"sintax"`: `>processid;tax=p:Phylum,c:Class,...`.

  - `"none"`: the raw BOLD sequence FASTA with `processid|taxon|marker`
    headers (no ranked taxonomy).

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly).

## Details

This function uses the BOLD public API hosted at `v3.boldsystems.org`,
which remains available after the main BOLD site's migration to v5. With
`tax_format = "none"` it queries the `sequence` endpoint (FASTA). With
`"dada2"`/`"sintax"` it queries the `combined` endpoint (TSV with the
full ranked taxonomy), keeps the requested `marker`, and writes a
taxonomy-headed FASTA (gaps removed). BOLD's taxonomy starts at phylum,
so the dada2 output has no kingdom level.

For very large taxa the download may be slow or hit server limits; use
narrower queries, or the
[BOLDconnectR](https://www.boldsystems.org/data/boldconnectr/) package
for the full v5 (BCDM) data model.

Please cite: Ratnasingham S & Hebert PDN (2007) BOLD: The Barcode of
Life Data System. Molecular Ecology Notes 7:355-364.
[doi:10.1111/j.1471-8286.2007.01678.x](https://doi.org/10.1111/j.1471-8286.2007.01678.x)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# COI reference for a genus, dada2 taxonomy headers
download_bold_db(dest_dir = "databases", taxon = "Danaus")

# ITS sequences for an order, SINTAX headers
download_bold_db(
  dest_dir = "databases",
  taxon = "Agaricales",
  marker = "ITS",
  tax_format = "sintax"
)
} # }
```
