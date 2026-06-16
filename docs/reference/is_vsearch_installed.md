# Check whether vsearch is installed

[![lifecycle-stable](https://img.shields.io/badge/lifecycle-stable-green)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Tests whether the `vsearch` executable is available on the system.

## Usage

``` r
is_vsearch_installed(path = find_vsearch())
```

## Arguments

- path:

  (Character, default `NULL`) Explicit path to the vsearch executable.
  If `NULL`, the function searches the system PATH.

## Value

`TRUE` if vsearch is available, `FALSE` otherwise.

## See also

[`find_vsearch()`](https://adrientaudiere.github.io/dbpq/reference/find_vsearch.md),
[`add_sh_to_taxonomy()`](https://adrientaudiere.github.io/dbpq/reference/add_sh_to_taxonomy.md)

## Examples

``` r
is_vsearch_installed()
#> [1] TRUE
```
