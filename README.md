# dbpq <img src="man/figures/logo.png" align="right" height="138" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**dbpq** manages FASTA reference databases used for taxonomic assignment in metabarcoding pipelines. It provides tools to **download**, **format**, **summarize**, and **modify** databases. Part of the [pqverse](https://github.com/adrientaudiere) ecosystem.

## Installation

```r
# Install from GitHub
# install.packages("pak")
pak::pak("adrientaudiere/dbpq")
```

## Supported databases

| Database | Function | Marker | Method |
|----------|----------|--------|--------|
| [UNITE](https://unite.ut.ee/) | `download_unite_db()` | ITS (fungi/eukaryotes) | Direct S3 download |
| [SILVA](https://www.arb-silva.de/) | `download_silva_db()` | 16S/18S (SSU, LSU) | Zenodo or arb-silva.de |
| [PR2](https://pr2-database.org/) | `download_pr2_db()` | 18S (protists) | GitHub releases (auto-detects latest) |
| [BOLD](https://www.boldsystems.org/) | `download_bold_db()` | COI, ITS, matK, rbcL | BOLD v3 API (query by taxon) |
| [MaarjAM](https://maarjam.ut.ee/) | `download_marjaam_db()` | 18S (AMF) | Direct download |
| [Eukaryome](https://eukaryome.org/) | `download_eukaryome_db()` | SSU, ITS, LSU | User-provided URL |

## Key features

### Download databases

```r
library(dbpq)

# Download UNITE v10.0 for fungi
download_unite_db(dest_dir = "databases")

# Download SILVA dada2-formatted training set
download_silva_db(dest_dir = "databases", format = "dada2")

# Download latest PR2 in dada2 format
download_pr2_db(dest_dir = "databases")
```

### Format taxonomy headers

Convert between taxonomy formats used by different classifiers:

```r
# Standard format -> SINTAX (for VSEARCH)
format2sintax(taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes")

# SINTAX -> dada2 (for dada2::assignTaxonomy())
format2dada2(taxnames = "AB123;tax=k:Fungi,p:Ascomycota", from_sintax = TRUE)

# Extract genus + species (for dada2::addSpecies())
format2dada2_species(taxnames = "AB123;k__Fungi;g__Aspergillus;s__fumigatus")
```

### Summarize databases

```r
# Count sequences
count_seq_db("my_database.fasta")

# Count sequences matching a pattern
count_pattern_db("my_database.fasta", "Fungi")

# List taxonomic ranks
list_ranks_db("my_database.fasta", rank_prefix = "p__")

# Full summary
summarize_db("my_database.fasta")
```

### Modify databases

```r
# Filter by taxon
filter_db("database.fasta", "Ascomycota", output = "ascomycota.fasta")

# Remove primers with cutadapt
cutadapt_rm_primers_db(
  "database.fasta",
  primer_fw = "GCATCGATGAAGAACGCAGC",
  primer_rev = "TCCTCCGCTTATTGATATGC",
  output = "db_trimmed.fasta"
)
```

## Related packages

dbpq is part of the **pqverse**, a suite of R packages for metabarcoding analysis built around [phyloseq](https://joey711.github.io/phyloseq/) objects:

- [MiscMetabar](https://github.com/adrientaudiere/MiscMetabar) — Miscellaneous functions for metabarcoding analyses
- [tidypq](https://github.com/adrientaudiere/tidypq) — Tidyverse-style verbs for phyloseq objects
- [comparpq](https://github.com/adrientaudiere/comparpq) — Compare multiple phyloseq objects
- [taxinfo](https://github.com/adrientaudiere/taxinfo) — Taxonomy-based information from GBIF, Wikipedia, GloBI
