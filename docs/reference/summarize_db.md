# Summarize a FASTA reference database

Provides an overview of a FASTA reference database: number of sequences,
sequence length distribution, and taxonomic coverage at each rank.
Supports both prefix-based formats (unite, sintax, greengenes2) and
positional formats (dada2, pr2).

## Usage

``` r
summarize_db(
  file,
  rank_prefixes = c("k__", "p__", "c__", "o__", "f__", "g__", "s__"),
  tax_format = NULL
)
```

## Arguments

- file:

  (Character, required) Path to a FASTA file (plain or gzip).

- rank_prefixes:

  (Character vector) Taxonomic rank prefixes to summarize. Defaults to
  kingdom through species. Ignored if `tax_format` is provided.

- tax_format:

  (Character) If provided, one of `"unite"`, `"sintax"`,
  `"greengenes2"`, or `"pr2"`. Overrides `rank_prefixes` with the full
  set from
  [`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md).
  If `"auto"`, the format is detected from the file headers using
  [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md).
  If `NULL` (default), `rank_prefixes` is used as-is.

## Value

A list with components:

- `n_sequences`: total number of sequences

- `length_summary`: summary statistics of sequence lengths

- `ranks`: a named integer vector of annotated counts per rank

## See also

[`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md),
[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md),
[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)

## Author

Adrien Taudière

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
summarize_db(db)
#> Database: example_unite.fasta
#> Sequences: 5
#> Sequence length: 68-68 (mean: 68)
#>   k: 5 sequences with annotation
#>   p: 5 sequences with annotation
#>   c: 5 sequences with annotation
#>   o: 5 sequences with annotation
#>   f: 5 sequences with annotation
#>   g: 5 sequences with annotation
#>   s: 5 sequences with annotation
summarize_db(db, tax_format = "unite")
#> Database: example_unite.fasta
#> Sequences: 5
#> Sequence length: 68-68 (mean: 68)
#>   k: 5 sequences with annotation
#>   p: 5 sequences with annotation
#>   c: 5 sequences with annotation
#>   o: 5 sequences with annotation
#>   f: 5 sequences with annotation
#>   g: 5 sequences with annotation
#>   s: 5 sequences with annotation
```
