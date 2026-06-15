# Annotate query sequences with UNITE Species Hypothesis (SH) names

**\[experimental\]**

Runs `vsearch --usearch_global` to match query sequences against a UNITE
reference database, then extracts the Species Hypothesis (SH) identifier
from each best hit. The SH name is the first `|`-delimited field in
UNITE sequence identifiers (e.g. `SH123456.09FU`).

This function ports the logic of the nf-core/ampliseq
`add_sh_to_taxonomy.py` script into R, using vsearch directly instead of
requiring external lookup tables.

## Usage

``` r
add_sh_to_taxonomy(
  query_fasta,
  unite_db,
  vsearchpath = find_vsearch(),
  id = 0.97,
  maxaccepts = 1,
  maxrejects = 32,
  nproc = 1,
  top_hits_only = TRUE,
  keep_temporary_files = FALSE,
  verbose = FALSE
)
```

## Arguments

- query_fasta:

  (Character) Path to a FASTA file containing the query sequences (e.g.
  ASVs or OTUs).

- unite_db:

  (Character) Path to a UNITE reference FASTA file. The file can be in
  any format (SINTAX, UNITE default, etc.) as long as the sequence
  identifiers contain SH names as the first `|`-delimited field. Files
  downloaded via
  [`download_unite_db()`](https://adrientaudiere.github.io/dbpq/reference/download_unite_db.md)
  meet this requirement.

- vsearchpath:

  (Character) Path to the vsearch executable. Defaults to
  [`find_vsearch()`](https://adrientaudiere.github.io/dbpq/reference/find_vsearch.md).

- id:

  (Numeric, default `0.97`) Minimum sequence identity threshold (0–1)
  for vsearch `--id` parameter.

- maxaccepts:

  (Integer, default `1`) Maximum number of hits to accept per query. Set
  to `0` for unlimited hits (useful when multiple equally-good matches
  may have different SH names).

- maxrejects:

  (Integer, default `32`) Maximum number of rejected hits before
  stopping the search for a query.

- nproc:

  (Integer, default `1`) Number of threads for vsearch.

- top_hits_only:

  (Logical, default `TRUE`) If `TRUE`, only report the top hit per query
  (highest identity). If `FALSE`, report all accepted hits, which is
  useful for detecting ambiguous SH assignments.

- keep_temporary_files:

  (Logical, default `FALSE`) If `TRUE`, do not delete the temporary
  blast6 output file after parsing.

- verbose:

  (Logical, default `FALSE`) Print vsearch progress messages.

## Value

A data.frame with columns:

- `query`: Query sequence identifier.

- `sh_name`: Species Hypothesis name extracted from the best database
  hit (e.g. `SH123456.09FU`), or `NA` if no hit was found.

- `target`: Full identifier of the matched database sequence.

- `pct_id`: Percent identity of the match.

- `aln_len`: Alignment length.

- `mismatches`: Number of mismatches.

- `e_value`: E-value of the match.

- `is_ambiguous`: Logical; `TRUE` if multiple hits with the same top
  identity disagree on the SH name.

## See also

[`download_unite_db()`](https://adrientaudiere.github.io/dbpq/reference/download_unite_db.md),
[`is_vsearch_installed()`](https://adrientaudiere.github.io/dbpq/reference/is_vsearch_installed.md),
[`find_vsearch()`](https://adrientaudiere.github.io/dbpq/reference/find_vsearch.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download a UNITE database first
unite_file <- download_unite_db(
  version = "10.0",
  taxonomic_format = "sintax",
  taxon_group = "fungi"
)

# Annotate ASVs with SH names
sh_res <- add_sh_to_taxonomy(
  query_fasta = "asvs.fasta",
  unite_db = unite_file,
  id = 0.97
)
head(sh_res)

# Check for ambiguous assignments
sh_res[sh_res$is_ambiguous, ]
} # }
```
