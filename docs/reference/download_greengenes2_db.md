# Download a Greengenes2 reference database

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the Greengenes2 16S rRNA database. By default, downloads the
dada2-formatted training sets from Zenodo (maintained by Benjamin
Callahan). Alternatively, downloads backbone sequences from the
Greengenes2 FTP server.

Note that Greengenes2 uses `d__` (domain) instead of `k__` (kingdom) as
the first rank prefix. Use `tax_format = "greengenes2"` with
[`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
and
[`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
for correct parsing.

## Usage

``` r
download_greengenes2_db(
  dest_dir = ".",
  version = "2024.09",
  format = c("dada2", "dada2_species", "fasta"),
  tax_format = c("dada2", "sintax", "keep"),
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- version:

  (Character, default `"2024.09"`) Greengenes2 version in `YYYY.MM`
  format.

- format:

  (Character, default `"dada2"`) One of:

  - `"dada2"`: dada2-formatted training set from Zenodo (recommended for
    [`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)).

  - `"dada2_species"`: species-level training set for
    [`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
    (includes species).

  - `"fasta"`: plain FASTA sequences from the FTP server.

- tax_format:

  (Character, default `"dada2"`) How to write taxonomy in the headers of
  the `"dada2"`/`"dada2_species"` training set. The Greengenes2 trainset
  ships with `d__`/`p__` rank prefixes, which
  [`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
  and
  [`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html)
  reject. One of:

  - `"dada2"`: strip the prefixes to unprefixed, positional dada2
    (`>Bacteria;Pseudomonadota;...;`).

  - `"sintax"`: rewrite as `>ID;tax=d:Bacteria,p:...`.

  - `"keep"`: leave the original `d__`-prefixed headers untouched.
    Ignored for `format = "fasta"`.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the downloaded file (invisibly).

## Details

The dada2-formatted files are maintained by Benjamin Callahan on Zenodo
and are the same source as the SILVA dada2 training sets. See
<https://benjjneb.github.io/dada2/training.html> for details.

The Greengenes2 trainset uses `d__`/`p__` rank prefixes. By default
(`tax_format = "dada2"`) the prefixes are stripped so the file is
directly usable by
[`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
and `add_new_taxonomy_pq()`.

Please cite: McDonald D et al. (2024) Greengenes2 unifies microbial data
in a single reference tree. Nature Biotechnology 42:715-718.
[doi:10.1038/s41587-023-01845-1](https://doi.org/10.1038/s41587-023-01845-1)

## See also

[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download dada2-formatted Greengenes2
download_greengenes2_db(dest_dir = "databases")

# Download plain FASTA from FTP
download_greengenes2_db(dest_dir = "databases", format = "fasta")
} # }
```
