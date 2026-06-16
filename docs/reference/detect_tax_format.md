# Detect taxonomy format from FASTA headers

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Reads a few sequence headers from a FASTA file and guesses the taxonomy
format based on characteristic patterns.

## Usage

``` r
detect_tax_format(file, n_headers = 20L)
```

## Arguments

- file:

  (Character, required) Path to a FASTA file (plain or gzip).

- n_headers:

  (Integer, default `20`) Number of headers to inspect.

## Value

A character string: one of `"unite"`, `"sintax"`, `"greengenes2"`,
`"pr2"`, or `"unknown"`.

## See also

[`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md),
[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md),
[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
detect_tax_format(db)
#> [1] "unite"
```
