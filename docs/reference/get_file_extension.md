# Get file extension(s)

[![lifecycle-stable](https://img.shields.io/badge/lifecycle-stable-green)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Returns all extensions from a file name. Double extensions such as
`.fasta.gz` are treated as a first-class case and returned as a
two-element vector (e.g. `c("fasta", "gz")`).

## Usage

``` r
get_file_extension(file_path)
```

## Arguments

- file_path:

  (Character, required) Path to a file.

## Value

A character vector of file extensions (one element per extension).

## Examples

``` r
get_file_extension("my_database.fasta")
#> [1] "fasta"
get_file_extension("my_database.fasta.gz")
#> [1] "fasta" "gz"   
```
