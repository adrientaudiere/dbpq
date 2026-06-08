# Get the default unwanted taxonomy patterns

Returns
[`MiscMetabar::unwanted_tax_patterns`](https://adrientaudiere.github.io/MiscMetabar/reference/unwanted_tax_patterns.html)
when MiscMetabar is installed, otherwise falls back to a built-in copy
of the same named character vector.

## Usage

``` r
unwanted_tax_patterns_default()
```

## Value

A named character vector (names = descriptions, values = regex
patterns).
