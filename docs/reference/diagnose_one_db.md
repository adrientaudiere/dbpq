# Diagnose a single FASTA database

Diagnose a single FASTA database

## Usage

``` r
diagnose_one_db(
  file,
  tax_format = "auto",
  min_length = 200L,
  check_duplicates = TRUE
)
```

## Arguments

- file:

  Path to a FASTA file.

- tax_format:

  Taxonomy format or `"auto"`.

- min_length:

  Minimum acceptable sequence length.

- check_duplicates:

  Whether to detect duplicated sequences.

## Value

A list with `stats` (one-row tibble), `coverage` (tibble), and
`warnings` (tibble).
