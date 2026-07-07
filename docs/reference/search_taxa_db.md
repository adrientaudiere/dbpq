# Search sequences by taxonomic name in a FASTA database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Searches a FASTA database (plain or gzip) for sequences whose header
matches a set of taxonomic name parts. This is useful to retrieve all
sequences assigned to a given taxon across databases that use different
header formats (e.g. UNITE `g__Apiotrichum;s__akiyoshidainum` vs SINTAX
`k:Fungi,...,g:Apiotrichum,s:akiyoshidainum`).

Matching is case-insensitive by default and based on substrings, so the
rank prefixes and separators used by a given format do not matter.
Provide multiple name parts in `taxa` to narrow the search: by default a
header matches only when **all** parts are present (`match = "all"`);
use `match = "any"` to match when at least one part is present.

On Linux/macOS, filtering is done with `awk` in a single streaming pass
over the file, so memory usage stays low even for multi-GB reference
databases — only the matched records are loaded into R. On Windows (or
whenever `awk` is unavailable), the function automatically falls back to
an in-memory
[`Biostrings::readDNAStringSet()`](https://rdrr.io/pkg/Biostrings/man/XStringSet-io.html)
filter, which is slower and more memory-hungry for large databases but
produces the same result.

## Usage

``` r
search_taxa_db(
  file,
  taxa,
  match = c("all", "any"),
  case_sensitive = FALSE,
  output_path = NULL
)
```

## Arguments

- file:

  (Character, required) Path to a FASTA file (plain or gzip).

- taxa:

  (Character, required) One or more taxonomic name parts to search for
  in sequence headers, e.g. `c("Apiotrichum", "akiyoshidainum")`.

- match:

  (Character, default `"all"`) Whether a header must contain all
  (`"all"`) or at least one (`"any"`) of the `taxa` parts.

- case_sensitive:

  (Logical, default `FALSE`) If `TRUE`, matching is case-sensitive.

- output_path:

  (Character, default `NULL`) Optional path to write the matched
  sequences to a FASTA file. A `.gz` extension produces a gzipped file.
  When set, the
  [Biostrings::DNAStringSet](https://rdrr.io/pkg/Biostrings/man/XStringSet-class.html)
  is returned invisibly.

## Value

A
[Biostrings::DNAStringSet](https://rdrr.io/pkg/Biostrings/man/XStringSet-class.html)
of the matching sequences, with original headers preserved (including
all taxonomy information). An empty `DNAStringSet` (length 0) is
returned when nothing matches.

## See also

[`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md)
for a shell-based header filter that writes to a file;
[`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md)
to reformat the retrieved sequences.

## Author

Adrien Taudière

## Examples

``` r
db <- system.file("extdata", "example_unite.fasta", package = "dbpq")

# Retrieve all Amanita sequences (single name part)
search_taxa_db(db, "Amanita")
#> DNAStringSet object of length 2:
#>     width seq                                               names               
#> [1]    68 ATCGATCGTAGCTAGCATCGATC...AGCATCGATCGTAGCTAGCATCG SH001|k__Fungi;p_...
#> [2]    68 GCTAGCTAGCATCGATCGGCTAG...CATCGATCGGCTAGCTAGCATCG SH002|k__Fungi;p_...

# Narrow to a species with two name parts (AND logic)
search_taxa_db(db, c("Amanita", "muscaria"))
#> DNAStringSet object of length 1:
#>     width seq                                               names               
#> [1]    68 ATCGATCGTAGCTAGCATCGATC...AGCATCGATCGTAGCTAGCATCG SH001|k__Fungi;p_...

# Match any of several genera (OR logic)
search_taxa_db(db, c("Amanita", "Fusarium"), match = "any")
#> DNAStringSet object of length 4:
#>     width seq                                               names               
#> [1]    68 ATCGATCGTAGCTAGCATCGATC...AGCATCGATCGTAGCTAGCATCG SH001|k__Fungi;p_...
#> [2]    68 GCTAGCTAGCATCGATCGGCTAG...CATCGATCGGCTAGCTAGCATCG SH002|k__Fungi;p_...
#> [3]    68 TTAAGGCCTTAAGGCCTTAAGGC...GCCTTAAGGCCTTAAGGCCTTAA SH003|k__Fungi;p_...
#> [4]    68 CCGGAATTCCGGAATTCCGGAAT...ATTCCGGAATTCCGGAATTCCGG SH004|k__Fungi;p_...

# Write the result to a gzipped FASTA file and read it back
out <- tempfile(fileext = ".fasta.gz")
search_taxa_db(db, "Boletus", output_path = out)
Biostrings::readDNAStringSet(out)
#> DNAStringSet object of length 1:
#>     width seq                                               names               
#> [1]    68 AAATTTGGGCCCAAATTTGGGCC...CCCAAATTTGGGCCCAAATTTGG SH005|k__Fungi;p_...
```
