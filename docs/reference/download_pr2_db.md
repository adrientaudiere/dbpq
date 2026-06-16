# Download a PR2 reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the PR2 protist ribosomal reference database from GitHub
releases. PR2 provides 18S rRNA gene sequences for protists and other
eukaryotes.

For more advanced access to PR2 data (e.g., full taxonomy tables,
metadata, or custom queries), see the
[pr2database](https://pr2database.github.io/pr2database/) R package.

## Usage

``` r
download_pr2_db(
  dest_dir = ".",
  version = NULL,
  format = c("dada2", "mothur", "UTAX", "sintax"),
  marker = c("SSU", "plastid"),
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- version:

  (Character) PR2 version number (e.g., `"5.0.0"`). If `NULL` (default),
  the latest release is fetched from GitHub.

- format:

  (Character, default `"dada2"`) One of `"dada2"`, `"mothur"`, `"UTAX"`,
  or `"sintax"` (alias for `"UTAX"`). See **Taxonomic ranks** below: the
  `"dada2"` file keeps PR2's 9 ranks, whereas the `"UTAX"`/`"sintax"`
  file collapses them to 8 (Division and Subdivision are merged).

- marker:

  (Character, default `"SSU"`) One of `"SSU"` or `"plastid"`.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly).

## Details

PR2 releases are hosted on GitHub at
<https://github.com/pr2database/pr2database/releases>.

### Taxonomic ranks

PR2 uses **9** taxonomic ranks. The `"dada2"` file keeps all nine as a
positional, semicolon-delimited lineage (no rank prefixes); pass them to
[`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
(via
[`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html)
with `method = "dada2"`) through `taxLevels`:

`c("Domain", "Supergroup", "Division", "Subdivision", "Class", "Order", "Family", "Genus", "Species")`

The `"UTAX"`/`"sintax"` file targets VSEARCH/USEARCH SINTAX and uses the
**8** standard single-letter rank prefixes (`k, d, p, c, o, f, g, s`).
To fit PR2's nine ranks onto them, PR2 **merges Division and
Subdivision** into the `p:` rank (joined by `-`). The 9 → 8 mapping is:

|                        |                                        |
|------------------------|----------------------------------------|
| PR2 rank (dada2)       | SINTAX prefix (UTAX)                   |
| Domain                 | `k:`                                   |
| Supergroup             | `d:`                                   |
| Division + Subdivision | `p:` (e.g. `Alveolata-Dinoflagellata`) |
| Class                  | `c:`                                   |
| Order                  | `o:`                                   |
| Family                 | `f:`                                   |
| Genus                  | `g:`                                   |
| Species                | `s:`                                   |

Mind the per-method argument when calling
[`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html):

- `method = "dada2"` (the `"dada2"` download) keeps all 9 ranks — pass
  the 9 names above as **`taxLevels`** (forwarded to
  [`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)).

- `method = "sintax"` (the `"sintax"`/`"UTAX"` download) has 8 ranks —
  pass 8 names as **`taxa_ranks`**, e.g.
  `c("Domain", "Supergroup", "Division_Subdivision", "Class", "Order", "Family", "Genus", "Species")`.
  The dada2 `taxLevels` argument is **ignored** by the SINTAX path, so
  the default 7 ranks would be used and parsing the 8-rank output fails.

Please cite: Guillou L et al. (2013) The Protist Ribosomal Reference
database (PR2). Nucleic Acids Research 41:D1108-D1113.
[doi:10.1093/nar/gks1160](https://doi.org/10.1093/nar/gks1160)

## See also

[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md),
[pr2database](https://pr2database.github.io/pr2database/) R package

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download latest PR2 in dada2 format
download_pr2_db(dest_dir = "databases")

# Download specific version in UTAX format
download_pr2_db(dest_dir = "databases", version = "5.0.0", format = "UTAX")
} # }
```
