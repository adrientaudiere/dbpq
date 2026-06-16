# Format taxonomy headers for dada2::addSpecies

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Converts taxonomy headers to the format expected by
[`dada2::addSpecies()`](https://rdrr.io/pkg/dada2/man/addSpecies.html):
`ID Genus Species`. Wrapper around
[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md).

## Usage

``` r
format2dada2_species(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL
)
```

## Arguments

- fasta_db:

  (Character) Path to a FASTA file. Mutually exclusive with `taxnames`.

- taxnames:

  (Character vector) Taxonomy header strings (without leading `>`).
  Mutually exclusive with `fasta_db`.

- input_format:

  (Character, default `"auto"`) Input taxonomy format. One of `"auto"`,
  `"sintax"`, `"unite"`, `"greengenes2"`.

- output_path:

  (Character) If provided and `fasta_db` is used, write the reformatted
  FASTA to this path.

## Value

If `taxnames` is used, a character vector. If `fasta_db` is used, a
`DNAStringSet` with reformatted names.

## See also

[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md),
[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md)

## Author

Adrien Taudière

## Examples

``` r
# UNITE format → dada2_species
format2dada2_species(
  taxnames = "AB123;k__Fungi;g__Aspergillus;s__fumigatus"
)
#> [1] "AB123 Aspergillus fumigatus"

# SINTAX format → dada2_species
format2dada2_species(
  taxnames = "AB123;tax=k:Fungi,g:Aspergillus,s:fumigatus",
  input_format = "sintax"
)
#> [1] "AB123 Aspergillus fumigatus"
```
