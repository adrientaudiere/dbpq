# Format taxonomy headers for dada2::assignTaxonomy

Converts taxonomy headers to the format expected by
[`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html):
unprefixed semicolon-delimited taxonomy
(`>Kingdom;Phylum;Class;Order;Family;Genus;`). Wrapper around
[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md).

## Usage

``` r
format2dada2(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL,
  pattern_to_remove = NULL
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
  FASTA to this path. The `DNAStringSet` is returned invisibly.

- pattern_to_remove:

  (Character) Optional regex pattern to remove from the reformatted
  names (applied after conversion).

## Value

If `taxnames` is used, a character vector. If `fasta_db` is used, a
`DNAStringSet` with reformatted names. When `output_path` is provided,
returned invisibly.

## See also

[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md),
[`format2dada2_species()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2_species.md)

## Author

Adrien Taudière

## Examples

``` r
# SINTAX format → dada2
format2dada2(
  taxnames = "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes"
)
#> [1] "Fungi;Ascomycota;Sordariomycetes;"

# UNITE format → dada2
format2dada2(
  taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes",
  input_format = "unite"
)
#> [1] "Fungi;Ascomycota;Sordariomycetes;"
```
