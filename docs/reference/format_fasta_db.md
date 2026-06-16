# Convert a FASTA database to a specified taxonomy format

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Detects (or uses) the input taxonomy format and rewrites sequence
headers to the requested output format. This is the primary conversion
function;
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md),
[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
and
[`format2dada2_species()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2_species.md)
are convenience wrappers around it.

Supported **input** formats (prefix-based, with detectable rank labels):
`"sintax"`, `"unite"`, `"greengenes2"`.

Supported **output** formats:

- `"sintax"` — VSEARCH/USEARCH SINTAX (`>ID;tax=k:Kingdom,p:Phylum,...`)

- `"unite"` — UNITE default (`>ID;k__Kingdom;p__Phylum;...`)

- `"greengenes2"` — Greengenes2 (`>ID d__Domain;p__Phylum;...`)

- `"dada2"` — Unprefixed semicolon-delimited (`>Kingdom;Phylum;...;`)

- `"dada2_species"` — For
  [`dada2::addSpecies()`](https://rdrr.io/pkg/dada2/man/addSpecies.html)
  (`>ID Genus Species`)

Positional formats (`"pr2"`, `"dada2"`) can be detected by
[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)
but cannot be used as input for conversion because they lack rank
labels.

## Usage

``` r
format_fasta_db(
  fasta_db = NULL,
  taxnames = NULL,
  output_format = c("sintax", "unite", "greengenes2", "dada2", "dada2_species"),
  input_format = "auto",
  output_path = NULL,
  id_prefix = "seq"
)
```

## Arguments

- fasta_db:

  (Character) Path to a FASTA file (plain or gzipped). Mutually
  exclusive with `taxnames`.

- taxnames:

  (Character vector) Taxonomy header strings (without leading `>`).
  Mutually exclusive with `fasta_db`.

- output_format:

  (Character) Target format. One of `"sintax"`, `"unite"`,
  `"greengenes2"`, `"dada2"`, `"dada2_species"`.

- input_format:

  (Character, default `"auto"`) Input format. One of `"auto"`
  (auto-detect via
  [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)),
  `"sintax"`, `"unite"`, `"greengenes2"`, `"dada2"`. The positional
  `"dada2"` input (taxonomy-only headers, no sequence ID) is assigned
  ranks by position (`d,p,c,o,f,g,s`); see `id_prefix` for the generated
  labels.

- output_path:

  (Character) If provided and `fasta_db` is used, write the reformatted
  FASTA to this path and return the `DNAStringSet` invisibly.

- id_prefix:

  (Character, default `"seq"`) Prefix used to build synthetic sequential
  sequence IDs (e.g. `"seq000001"`) for input formats that carry no
  per-sequence identifier (`"dada2"`). Ignored when the input already
  provides IDs.

## Value

If `taxnames` is used, a character vector of reformatted headers. If
`fasta_db` is used, a `DNAStringSet` with reformatted names (invisibly
when `output_path` is given).

## See also

[`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md),
[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`format2dada2_species()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2_species.md)

## Author

Adrien Taudière

## Examples

``` r
# UNITE → SINTAX
format_fasta_db(
  taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes",
  output_format = "sintax"
)
#> [1] "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes"

# SINTAX → UNITE
format_fasta_db(
  taxnames = "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes",
  output_format = "unite"
)
#> [1] "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes"

# Greengenes2 → dada2
format_fasta_db(
  taxnames = "abc123 d__Bacteria;p__Pseudomonadota;g__Escherichia",
  output_format = "dada2"
)
#> [1] "Bacteria;Pseudomonadota;Escherichia;"
```
