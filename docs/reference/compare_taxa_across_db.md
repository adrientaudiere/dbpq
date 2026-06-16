# Compare taxa across databases, per rank

Builds, for each rank, a presence/absence membership table across the
databases, the per-signature summary (taxa and sequence totals), and the
Venn/UpSet plot.

## Usage

``` r
compare_taxa_across_db(
  taxa,
  weight_by_seqs = FALSE,
  venn_max = 7L,
  build_plots = TRUE
)
```
