# Detect taxonomy format from a vector of FASTA headers

Header-based core of
[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md).
Operates on an in-memory character vector of header lines so callers
that already hold the headers (e.g.
[`diagnose_db()`](https://adrientaudiere.github.io/dbpq/reference/diagnose_db.md))
need not re-read the file.

## Usage

``` r
detect_tax_format_from_headers(headers, n_headers = 20L)
```

## Arguments

- headers:

  (Character vector) FASTA header lines (with or without the leading
  `>`).

- n_headers:

  (Integer, default `20`) Number of headers to inspect.

## Value

A character string: one of `"unite"`, `"sintax"`, `"greengenes2"`,
`"pr2"`, `"dada2"`, or `"unknown"`.
