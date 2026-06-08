# Count lines matching a pattern in a FASTA file

Count lines (sequences if fasta file) matching a pattern. Accepts gzip
files. May not work on Windows.

## Usage

``` r
count_pattern_db(file, pattern = ">")
```

## Arguments

- file:

  (Character, required) Path to a file (plain or gzip), often a FASTA
  file.

- pattern:

  (Character, default `">"`) A pattern to search for.

## Value

An integer, the number of matching lines.

## See also

[`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md),
[`count_seq_db()`](https://adrientaudiere.github.io/dbpq/reference/count_seq_db.md)

## Author

Adrien Taudière

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
count_pattern_db(db, "Amanita")
#> [1] 2
```
