# Filter a FASTA database by taxonomic pattern

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Filters sequences from a FASTA database whose header lines match a given
pattern. Accepts gzip files. May not work on Windows.

## Usage

``` r
filter_db(
  ref_fasta,
  pattern,
  output = NULL,
  force_two_lines_per_seq = TRUE,
  keep_temporary_files = FALSE
)
```

## Arguments

- ref_fasta:

  (Character, required) Path to a FASTA file (plain or gzip).

- pattern:

  (Character, required) A pattern to search for in sequence headers.

- output:

  (Character, required) Path to the output FASTA file (must not be
  gzipped).

- force_two_lines_per_seq:

  (Logical, default `TRUE`) Force the FASTA file to have exactly two
  lines per sequence (one header, one nucleotide line). If `FALSE`, the
  input must already be in this format.

- keep_temporary_files:

  (Logical, default `FALSE`) If `TRUE` and `force_two_lines_per_seq` is
  `TRUE`, keep intermediate temporary files.

## Value

The path to the output file (invisibly).

## See also

[`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md)

## Author

Adrien Taudière

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
out <- tempfile(fileext = ".fasta")
filter_db(db, "Amanita", output = out)
count_seq_db(out)
#> [1] 2
```
