# Get rank information for a taxonomy format

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Returns the taxonomic rank information for common reference database
formats. For prefix-based formats (unite, sintax, greengenes2), returns
a named character vector of prefixes. For positional formats (pr2),
returns a named integer vector of rank positions.

Use the result with
[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
and
[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
via their `tax_format` parameter.

Note:
[`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
is a classifier, not a taxonomy format. It accepts any
semicolon-separated taxonomy with any number of levels, regardless of
whether prefixes are present or not. Use the `taxLevels` argument in
[`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
to specify the rank names.

## Usage

``` r
tax_prefixes(tax_format = c("unite", "sintax", "greengenes2", "pr2"))
```

## Arguments

- tax_format:

  (Character) One of:

  - `"unite"`: `k__`/`p__`/... format used by UNITE general FASTA
    releases.

  - `"sintax"`: `d:`/`k:`/`p:`/... format used by VSEARCH SINTAX and
    USEARCH UTAX databases (UNITE SINTAX, PR2 UTAX). Note that UNITE
    SINTAX files use `k:` (kingdom) as their first rank and do not
    include `d:` (domain). When calling
    [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
    on a UNITE SINTAX file, the `d:` row will show 0 sequences — this is
    expected.

  - `"greengenes2"`: `d__`/`p__`/... format used by Greengenes2 (starts
    with domain `d__` instead of kingdom `k__`).

  - `"pr2"`: positional format with 9 levels specific to protist
    taxonomy: Domain, Supergroup, Division, Subdivision, Class, Order,
    Family, Genus, Species.

## Value

For prefix-based formats: a named character vector of rank prefixes. For
positional formats: a named integer vector of rank positions.

## See also

[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md),
[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md),
[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)

## Examples

``` r
tax_prefixes("unite")
#>     k     p     c     o     f     g     s 
#> "k__" "p__" "c__" "o__" "f__" "g__" "s__" 
tax_prefixes("sintax")
#>    d    k    p    c    o    f    g    s 
#> "d:" "k:" "p:" "c:" "o:" "f:" "g:" "s:" 
tax_prefixes("greengenes2")
#>     d     p     c     o     f     g     s 
#> "d__" "p__" "c__" "o__" "f__" "g__" "s__" 
tax_prefixes("pr2")
#>      Domain  Supergroup    Division Subdivision       Class       Order 
#>           1           2           3           4           5           6 
#>      Family       Genus     Species 
#>           7           8           9 
```
