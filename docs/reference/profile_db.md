# Profile the taxonomic content of one or several FASTA databases

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Builds a taxonomic profile of one or more FASTA reference databases. It
first runs
[`diagnose_db()`](https://adrientaudiere.github.io/dbpq/reference/diagnose_db.md)
(format/integrity/quality checks) and then adds:

- a **richness** table and bar plot giving the number of distinct taxa
  (levels) annotated at each taxonomic rank, and

- when several databases are supplied, a **cross-database comparison**
  of the taxa present at each rank, drawn as a Venn diagram
  (ggVennDiagram, up to `venn_max` databases) or an UpSet plot
  (ComplexUpset), with one plot per rank.

By default the comparison overlaps the *sets of distinct taxon names* at
each rank (presence/absence). With `weight_by_seqs = TRUE` the UpSet
bars instead show the total number of sequences backing the taxa in each
intersection (summed across the databases that contain each taxon).

## Usage

``` r
profile_db(
  files,
  tax_format = "auto",
  weight_by_seqs = FALSE,
  plot = TRUE,
  venn_max = 7L,
  verbose = TRUE,
  ...
)
```

## Arguments

- files:

  (Character vector, required) One or more paths to FASTA files (plain
  or gzip).

- tax_format:

  (Character, default `"auto"`) Taxonomy format, passed to
  [`diagnose_db()`](https://adrientaudiere.github.io/dbpq/reference/diagnose_db.md)
  and used for taxon extraction. One of `"auto"`, `"unite"`, `"sintax"`,
  `"greengenes2"`, `"pr2"`, or `"dada2"`.

- weight_by_seqs:

  (Logical, default `FALSE`) When `TRUE`, the cross-database UpSet plot
  weights each intersection by the number of sequences (summed over the
  databases containing each taxon) rather than by the number of taxa.
  Forces an UpSet plot (Venn diagrams cannot be weighted) and therefore
  needs ComplexUpset; with ggplot2 \>= 4.0.0 this requires the dev
  version (\>= 1.3.6, install with
  `remotes::install_github("krassowski/complex-upset")`). When it is
  unavailable, an unweighted Venn is drawn instead and the weighted
  counts are still returned in `comparison$signatures`.

- plot:

  (Logical, default `TRUE`) Whether to build plots. Requires ggplot2;
  the comparison plots additionally require ggVennDiagram and/or
  ComplexUpset.

- venn_max:

  (Integer, default `7`) Maximum number of databases for which a Venn
  diagram is drawn; beyond this an UpSet plot is used. (Also forced to
  UpSet when `weight_by_seqs = TRUE`.)

- verbose:

  (Logical, default `TRUE`) Whether to show a cli progress bar while
  reading files and print a summary report.

- ...:

  Further arguments passed to
  [`diagnose_db()`](https://adrientaudiere.github.io/dbpq/reference/diagnose_db.md)
  (e.g. `min_length`, `check_duplicates`).

## Value

An object of class `"dbpq_profile"`: a list with components

- `diagnosis`:

  The
  [`diagnose_db()`](https://adrientaudiere.github.io/dbpq/reference/diagnose_db.md)
  result (a `dbpq_diagnosis`).

- `taxa`:

  A long [tibble](https://tibble.tidyverse.org/reference/tibble.html)
  (`file`, `rank`, `taxon`, `n_seqs`) of every taxon found at every
  rank.

- `richness`:

  A tibble (`file`, `rank`, `n_levels`, `n_seqs_annotated`) of per-rank
  taxonomic richness.

- `comparison`:

  `NULL` for a single file; otherwise a list with `per_db` and
  `signatures` tibbles, per-rank `membership` data frames, and per-rank
  `plots`.

- `plots`:

  A list with `richness` (a ggplot) and `comparison` (a named list of
  per-rank Venn/UpSet plots, or `NULL`).

## See also

[`diagnose_db()`](https://adrientaudiere.github.io/dbpq/reference/diagnose_db.md),
[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md),
[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)

## Author

Adrien Taudière

## Examples

``` r
unite <- system.file("extdata", "example_unite.fasta", package = "dbpq")
prof <- profile_db(unite, verbose = FALSE)
prof$richness
#> # A tibble: 7 × 4
#>   file                rank  n_levels n_seqs_annotated
#>   <chr>               <chr>    <int>            <int>
#> 1 example_unite.fasta c            2                5
#> 2 example_unite.fasta f            3                5
#> 3 example_unite.fasta g            3                5
#> 4 example_unite.fasta k            1                5
#> 5 example_unite.fasta o            3                5
#> 6 example_unite.fasta p            2                5
#> 7 example_unite.fasta s            5                5

# Compare two databases (needs ggVennDiagram / ComplexUpset for the plots)
# \donttest{
sintax <- system.file("extdata", "example_sintax.fasta", package = "dbpq")
prof2 <- profile_db(c(unite, sintax), verbose = FALSE)
prof2$comparison$signatures
#> # A tibble: 9 × 5
#>   rank  members                                    n_members n_taxa n_seqs
#>   <chr> <chr>                                          <int>  <int>  <int>
#> 1 k     example_unite.fasta & example_sintax.fasta         2      1      8
#> 2 d     example_sintax.fasta                               1      1      3
#> 3 p     example_unite.fasta & example_sintax.fasta         2      2      8
#> 4 c     example_unite.fasta & example_sintax.fasta         2      2      8
#> 5 o     example_unite.fasta & example_sintax.fasta         2      3      8
#> 6 f     example_unite.fasta & example_sintax.fasta         2      3      8
#> 7 g     example_unite.fasta & example_sintax.fasta         2      3      8
#> 8 s     example_unite.fasta                                1      2      2
#> 9 s     example_unite.fasta & example_sintax.fasta         2      3      6
# }
```
