# Count sequences in a FASTA file

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Counts the number of sequences in a FASTA file by counting header lines
(lines starting with `>`). Accepts gzip files.

## Usage

``` r
count_seq_db(file)
```

## Arguments

- file:

  (Character, required) Path to a FASTA file (plain or gzip).

## Value

An integer, the number of sequences.

## See also

[`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md)

## Author

Adrien Taudière

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
count_seq_db(db)
#> [1] 5
```
