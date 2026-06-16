# Diagnose one or several FASTA reference databases

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Runs format, integrity, and quality checks on one or more FASTA
reference databases and returns a structured diagnosis: per-file
statistics, per-rank taxonomic coverage, a table of collected warnings,
a cross-file comparison (which flags problems such as a **mixed taxonomy
format** across files), and (optionally) diagnostic plots.

The three axes checked are:

- Format:

  Is the file valid FASTA? Which taxonomy format is detected
  ([`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md))?
  Are the taxonomy prefixes consistent across all headers?

- Integrity:

  Can the file be read to completion (a truncated gzip fails here)? Are
  there empty sequences or duplicated sequence IDs?

- Quality:

  Sequence-length distribution and unusually short sequences, percentage
  of sequences annotated at each rank, ambiguous (non-ACGT) bases,
  duplicated sequences, and unwanted taxonomic values
  ([`count_unwanted_tax()`](https://adrientaudiere.github.io/dbpq/reference/count_unwanted_tax.md)).

## Usage

``` r
diagnose_db(
  files,
  tax_format = "auto",
  plot = TRUE,
  min_length = 200L,
  check_duplicates = TRUE,
  verbose = TRUE
)
```

## Arguments

- files:

  (Character vector, required) One or more paths to FASTA files (plain
  or gzip).

- tax_format:

  (Character, default `"auto"`) Taxonomy format to assume for every
  file. One of `"auto"`, `"unite"`, `"sintax"`, `"greengenes2"`,
  `"pr2"`, or `"dada2"`. When `"auto"` (default) the format is detected
  per file from its headers.

- plot:

  (Logical, default `TRUE`) Whether to build diagnostic plots. Requires
  the ggplot2 package; when it is not installed, `$plots` is `NULL` and
  a message is emitted.

- min_length:

  (Integer, default `200`) Sequences shorter than this are counted as
  "short" and raise a quality warning.

- check_duplicates:

  (Logical, default `TRUE`) Whether to look for duplicated sequences.
  This compares full sequences and can be slow on very large databases;
  set to `FALSE` to skip.

- verbose:

  (Logical, default `TRUE`) Whether to show a cli progress bar (with an
  ETA) while files are processed, then print a summary and the collected
  warnings.

## Value

An object of class `"dbpq_diagnosis"`: a list with components

- `stats`:

  A [tibble](https://tibble.tidyverse.org/reference/tibble.html), one
  row per file, with sequence counts, length statistics, and problem
  counts.

- `coverage`:

  A long tibble of per-rank annotation coverage (`file`, `rank`,
  `n_annotated`, `pct_annotated`).

- `warnings`:

  A tibble of collected issues (`file`, `check`, `severity`, `message`);
  `severity` is one of `"info"`, `"warning"`, `"error"`. Cross-file
  issues have `file = NA`.

- `cross_file`:

  A list describing agreement across files (`formats`,
  `format_agreement`, `n_files`).

- `plots`:

  A list of ggplot2 objects (`length`, `coverage`), or `NULL`.

## See also

[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md),
[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md),
[`count_unwanted_tax()`](https://adrientaudiere.github.io/dbpq/reference/count_unwanted_tax.md)

## Author

Adrien Taudière

## Examples

``` r
unite <- system.file("extdata", "example_unite.fasta", package = "dbpq")
diag <- diagnose_db(unite)
#> 
#> ── Diagnosed 1 database file ──
#> 
#> ℹ example_unite.fasta [unite]: 5 seqs, length 68-68 bp
#> 
#> ── Issues: 0 errors, 1 warning, 0 info 
#> ! example_unite.fasta (quality): 5 sequence(s) shorter than 200 bp.
diag$stats
#> # A tibble: 1 × 17
#>   file       path  format valid n_sequences length_min length_median length_mean
#>   <chr>      <chr> <chr>  <lgl>       <int>      <int>         <int>       <dbl>
#> 1 example_u… exam… unite  TRUE            5         68            68          68
#> # ℹ 9 more variables: length_max <int>, n_short <int>, n_empty_seq <int>,
#> #   n_dup_id <int>, n_dup_seq <int>, n_ambiguous_seq <int>,
#> #   pct_ambiguous_bases <dbl>, n_unwanted_tax <int>, n_warnings <int>

# Several files at once: a mismatched taxonomy format is flagged
sintax <- system.file("extdata", "example_sintax.fasta", package = "dbpq")
diag2 <- diagnose_db(c(unite, sintax))
#> 
#> ── Diagnosed 2 database files ──
#> 
#> ℹ example_unite.fasta [unite]: 5 seqs, length 68-68 bp
#> ℹ example_sintax.fasta [sintax]: 3 seqs, length 68-68 bp
#> ! Mixed taxonomy formats across files.
#> 
#> ── Issues: 0 errors, 3 warnings, 1 info 
#> ! example_unite.fasta (quality): 5 sequence(s) shorter than 200 bp.
#> ! example_sintax.fasta (quality): 3 sequence(s) shorter than 200 bp.
#> ℹ example_sintax.fasta (quality): 1 sequence(s) contain ambiguous (non-ACGT) bases (1.471% of all bases).
#> ! '<cross-file>' (format): Mixed taxonomy formats across files: unite, sintax. Databases may not be directly comparable or mergeable.
diag2$warnings
#> # A tibble: 4 × 4
#>   file                 check   severity message                                 
#>   <chr>                <chr>   <chr>    <chr>                                   
#> 1 example_unite.fasta  quality warning  5 sequence(s) shorter than 200 bp.      
#> 2 example_sintax.fasta quality warning  3 sequence(s) shorter than 200 bp.      
#> 3 example_sintax.fasta quality info     1 sequence(s) contain ambiguous (non-AC…
#> 4 NA                   format  warning  Mixed taxonomy formats across files: un…
```
