# Find the vsearch executable

Locates the `vsearch` executable on the system PATH, or verifies a
user-supplied path. This is a lightweight standalone version of the
helper found in MiscMetabar, so that dbpq does not need to depend on
MiscMetabar for vsearch operations.

## Usage

``` r
find_vsearch(path = NULL)
```

## Arguments

- path:

  (Character, default `NULL`) Explicit path to the vsearch executable.
  If `NULL`, the function searches the system PATH via
  [`Sys.which()`](https://rdrr.io/r/base/Sys.which.html).

## Value

A character string with the path to vsearch, or `NA` if not found.

## See also

[`is_vsearch_installed()`](https://adrientaudiere.github.io/dbpq/reference/is_vsearch_installed.md),
[`add_sh_to_taxonomy()`](https://adrientaudiere.github.io/dbpq/reference/add_sh_to_taxonomy.md)

## Examples

``` r
find_vsearch()
#> [1] "/usr/local/bin/vsearch"
```
