# Download a SILVA reference database NR99 version

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Downloads the SILVA ribosomal RNA database (16S/18S/23S/28S). By
default, downloads the dada2-formatted training sets from the official
arb-silva.de DADA2 release (available for both SSU and LSU). Can also
produce a SINTAX-formatted database (converted locally from the dada2
trainset) or download the raw SILVA NR99 export.

For the PARC version (all sequences, not clustered like NR99), see
`dada2:::makeSpeciesFasta_Silva()` on the manually downloaded FASTA
file.

## Usage

``` r
download_silva_db(
  dest_dir = ".",
  version = "138.2",
  target = c("SSU", "LSU"),
  format = c("dada2", "dada2_species", "sintax", "raw"),
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  (Character, default `"."`) Directory to save the downloaded file.

- version:

  (Character, default `"138.2"`) SILVA version number. Only the current
  SILVA release is hosted at the arb-silva DADA2 path used by the
  dada2/dada2_species/sintax formats.

- target:

  (Character, default `"SSU"`) One of `"SSU"` or `"LSU"`.

- format:

  (Character, default `"dada2"`) One of:

  - `"dada2"`: dada2-formatted `toSpecies` training set (NR99,
    recommended for
    [`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)).

  - `"dada2_species"`: species assignment file for
    [`dada2::addSpecies()`](https://rdrr.io/pkg/dada2/man/addSpecies.html).

  - `"sintax"`: VSEARCH/USEARCH SINTAX database, converted locally from
    the dada2 `toSpecies` trainset (7 ranks `d,p,c,o,f,g,s`). Sequence
    labels are synthetic (`SILVA<version>_<target>_NNNNNN`) because the
    dada2 trainset carries no accession. Written as a separate
    `*_sintax.fasta.gz` file.

  - `"raw"`: raw SILVA NR99 FASTA with taxonomy from arb-silva.de.

- verbose:

  (Logical, default `TRUE`) Print progress messages.

## Value

The path to the resulting file (invisibly). For `"sintax"` this is the
converted `*_sintax.fasta.gz`; the intermediate trainset is also kept in
`dest_dir`.

## Details

The dada2-formatted files are provided by arb-silva.de and are the
recommended format for
[`dada2::assignTaxonomy()`](https://rdrr.io/pkg/dada2/man/assignTaxonomy.html)
and
[`dada2::addSpecies()`](https://rdrr.io/pkg/dada2/man/addSpecies.html).
See <https://benjjneb.github.io/dada2/training.html> for details.

SILVA data is free for academic use. Commercial use requires a license.
See <https://www.arb-silva.de/silva-license-information/>.

Please cite: Quast C et al. (2013) The SILVA ribosomal RNA gene database
project. Nucleic Acids Research 41:D590-D596.
[doi:10.1093/nar/gks1219](https://doi.org/10.1093/nar/gks1219)

## See also

[`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
[`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md)

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
# Download dada2-formatted SILVA for assignTaxonomy()
download_silva_db(dest_dir = "databases")

# Download species assignment file
download_silva_db(dest_dir = "databases", format = "dada2_species")

# Download a SINTAX database for SSU (converted from the dada2 trainset)
download_silva_db(dest_dir = "databases", format = "sintax")

# SINTAX database for LSU
download_silva_db(dest_dir = "databases", target = "LSU", format = "sintax")

# Download raw SILVA NR99 FASTA
download_silva_db(dest_dir = "databases", format = "raw")
} # }
```
