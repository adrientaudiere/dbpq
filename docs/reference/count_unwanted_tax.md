# Count unwanted values in a taxonomy table

Scans a taxonomy table for common problematic values such as NA-like
strings, placeholder labels (`"unclassified"`, `"unknown"`, etc.), and
empty QIIME-style rank prefixes. The input can be a
[phyloseq](https://rdrr.io/pkg/phyloseq/man/phyloseq-class.html) object
or a FASTA reference database file.

Returns a tibble summarising, for each pattern found, how many matches
occur in each taxonomic rank.

## Usage

``` r
count_unwanted_tax(
  x,
  patterns = unwanted_tax_patterns_default(),
  tax_format = "auto"
)
```

## Arguments

- x:

  Either:

  - a character string giving the path to a FASTA file (plain or gzip),
    or

  - a [phyloseq](https://rdrr.io/pkg/phyloseq/man/phyloseq-class.html)
    object with a taxonomy table.

- patterns:

  (Character vector) Regular expressions to search for. When MiscMetabar
  is installed, defaults to
  [MiscMetabar::unwanted_tax_patterns](https://adrientaudiere.github.io/MiscMetabar/reference/unwanted_tax_patterns.html);
  otherwise falls back to a built-in copy of the same patterns. See
  **Details**.

- tax_format:

  (Character) Taxonomy format of the FASTA file. One of `"unite"`,
  `"sintax"`, `"greengenes2"`, `"pr2"`, or `"auto"`. Only used when `x`
  is a file path. If `"auto"` (default), the format is detected with
  [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md).
  Ignored when `x` is a phyloseq object.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- `pattern`:

  The regular expression that matched.

- `description`:

  A human-readable label for the pattern.

- `rank`:

  The taxonomic rank (column name) where matches were found.

- `n_matches`:

  Number of values matching the pattern in that rank.

- `example_values`:

  Up to 3 unique matching values (comma-separated).

Rows with zero matches are omitted.

## Details

The default patterns are:

- `"^[Nn][Aa][Nn]?$"`:

  NaN, nan, NA, na

- `"^[Nn]/[Aa]$"`:

  N/A, n/a

- `"^[Nn]one$"`:

  None, none

- `"^$"`:

  empty string

- `"^\\s+$"`:

  whitespace only

- `"[Uu]nclassified"`:

  unclassified, Unclassified, xxx_unclassified

- `"[Uu]nknown"`:

  unknown, Unknown, xxx_unknown

- `"[Uu]nidentified"`:

  unidentified, Unidentified

- `"[Uu]ncultured"`:

  uncultured, Uncultured

- `"[Ii]ncertae[_\\s]?[Ss]edis"`:

  incertae_sedis, Incertae sedis

- `"^[Mm]etagenome$"`:

  metagenome, Metagenome

- `"^[Ee]nvironmental"`:

  environmental, Environmental

- `"^[kpcofgs]__$"`:

  empty QIIME-style rank prefixes

## See also

[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md),
[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)

## Author

Adrien Taudière

## Examples

``` r
# From a FASTA file (no unwanted values in example data)
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
count_unwanted_tax(db)
#> No unwanted taxonomic values found.
#> # A tibble: 0 × 5
#> # ℹ 5 variables: pattern <chr>, description <chr>, rank <chr>, n_matches <int>,
#> #   example_values <chr>

if(requireNamespace("MiscMetabar", quietly = TRUE)) {
 ref_fasta <- Biostrings::readDNAStringSet(system.file("extdata",
   "mini_UNITE_fungi.fasta.gz",
   package = "MiscMetabar", mustWork = TRUE
 ))
data("data_fungi_mini", package = "MiscMetabar")
physeq_new <- MiscMetabar::assign_mmseqs2(
   MiscMetabar::data_fungi_mini,
   ref_fasta = ref_fasta,
   behavior = "add_to_phyloseq"
 )
count_unwanted_tax(physeq_new)
}
#> Found 42 unwanted value(s) matching 1 pattern(s) across 4 rank(s).
#> Tip: use MiscMetabar::verify_tax_table() to clean these values in your phyloseq object.
#> # A tibble: 4 × 5
#>   pattern                      description    rank      n_matches example_values
#>   <chr>                        <chr>          <chr>         <int> <chr>         
#> 1 "[Ii]ncertae[_\\s]?[Ss]edis" incertae sedis Family            4 Cantharellale…
#> 2 "[Ii]ncertae[_\\s]?[Ss]edis" incertae sedis Order_mm…         2 Agaricomycete…
#> 3 "[Ii]ncertae[_\\s]?[Ss]edis" incertae sedis Family_m…        15 Trechisporale…
#> 4 "[Ii]ncertae[_\\s]?[Ss]edis" incertae sedis Genus_mm…        21 Tricholomatac…
```
