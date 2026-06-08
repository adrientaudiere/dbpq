# Get file extension(s)

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
