# Format taxonomy headers to SINTAX format

Converts taxonomy headers to the VSEARCH SINTAX format
(`>ID;tax=k:Kingdom,p:Phylum,...`). Wrapper around
[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md).

## Usage

``` r
format2sintax(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL,
  id_prefix = "seq"
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
  `"unite"`, `"greengenes2"`, `"dada2"`.

- output_path:

  (Character) If provided and `fasta_db` is used, write the reformatted
  FASTA to this path.

- id_prefix:

  (Character, default `"seq"`) Prefix for synthetic sequence IDs
  generated when the input has none (e.g. `"dada2"`).

## Value

If `taxnames` is used, a character vector of reformatted names. If
`fasta_db` is used, a `DNAStringSet` with reformatted names.

## See also

[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md),
[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`format2dada2_species()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2_species.md)

## Author

Adrien Taudière

## Examples

``` r
# UNITE format → SINTAX
format2sintax(taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes")
#> [1] "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes"

# Greengenes2 format → SINTAX
format2sintax(
  taxnames = "abc123 d__Bacteria;p__Pseudomonadota",
  input_format = "greengenes2"
)
#> [1] "abc123;tax=d:Bacteria,p:Pseudomonadota"

# dada2 trainset (taxonomy-only, positional) → SINTAX with synthetic IDs
format2sintax(
  taxnames = "Bacteria;Pseudomonadota;Gammaproteobacteria;Vibrio;",
  input_format = "dada2",
  id_prefix = "SILVA_"
)
#> [1] "SILVA_000001;tax=d:Bacteria,p:Pseudomonadota,c:Gammaproteobacteria,o:Vibrio"
```
