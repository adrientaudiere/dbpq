# In-memory fallback for [`search_taxa_db()`](https://adrientaudiere.github.io/dbpq/reference/search_taxa_db.md)

Reads the whole FASTA with
[`Biostrings::readDNAStringSet()`](https://rdrr.io/pkg/Biostrings/man/XStringSet-io.html)
and filters headers in R. Used when the streaming `awk` path is
unavailable.

## Usage

``` r
.search_taxa_db_in_memory(file, taxa, match, case_sensitive)
```

## Arguments

- file:

  (Character) Path to a FASTA file (plain or gzip).

- taxa:

  (Character) Taxonomic name parts to search for.

- match:

  (Character) Either `"all"` or `"any"`.

- case_sensitive:

  (Logical) Whether matching is case-sensitive.

## Value

A
[Biostrings::DNAStringSet](https://rdrr.io/pkg/Biostrings/man/XStringSet-class.html)
of matching sequences.
