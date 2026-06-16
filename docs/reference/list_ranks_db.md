# List and count taxonomic ranks from a FASTA database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Extracts and counts occurrences of a given taxonomic rank from FASTA
sequence headers. Supports both prefix-based formats (unite, sintax,
greengenes2) and positional formats (dada2, pr2).

## Usage

``` r
list_ranks_db(
  file,
  rank_prefix = "k__",
  tax_format = NULL,
  rank_position = NULL
)
```

## Arguments

- file:

  (Character, required) Path to a FASTA file (plain or gzip).

- rank_prefix:

  (Character, default `"k__"`) The prefix identifying the taxonomic rank
  to extract (e.g., `"k__"` for kingdom, `"p__"` for phylum). Ignored if
  `tax_format` is provided.

- tax_format:

  (Character) If provided, one of `"unite"`, `"sintax"`,
  `"greengenes2"`, or `"pr2"`. Overrides `rank_prefix` with the first
  rank from
  [`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md).
  If `NULL` (default), `rank_prefix` is used as-is.

- rank_position:

  (Integer) For positional (prefix-less) taxonomy headers, the 1-based
  position of the rank to extract from the semicolon-delimited string.
  Can be used with `tax_format = "pr2"` or standalone (without
  `tax_format`). Ignored for prefix-based formats.

## Value

A named integer vector of counts, sorted in decreasing order. Names are
the taxonomic rank values.

## See also

[`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md),
[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md),
[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)

## Author

Adrien Taudière

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
list_ranks_db(db, rank_prefix = "p__")
#> p__Basidiomycota    p__Ascomycota 
#>                3                2 
list_ranks_db(db, tax_format = "unite")
#> k__Fungi 
#>        5 
```
