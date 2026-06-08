# Package index

## Download databases

Download latest versions of reference databases.

- [`download_unite_db()`](https://adrientaudiere.github.io/dbpq/reference/download_unite_db.md)
  : Download a UNITE reference database
- [`download_silva_db()`](https://adrientaudiere.github.io/dbpq/reference/download_silva_db.md)
  : Download a SILVA reference database NR99 version
- [`download_pr2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_pr2_db.md)
  : Download a PR2 reference database
- [`download_greengenes2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_greengenes2_db.md)
  : Download a Greengenes2 reference database
- [`download_rdp_db()`](https://adrientaudiere.github.io/dbpq/reference/download_rdp_db.md)
  : Download an RDP reference database
- [`download_midori2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_midori2_db.md)
  : Download a MIDORI2 reference database
- [`download_bold_db()`](https://adrientaudiere.github.io/dbpq/reference/download_bold_db.md)
  : Download sequences from BOLD Systems
- [`download_diatbarcode_db()`](https://adrientaudiere.github.io/dbpq/reference/download_diatbarcode_db.md)
  : Download a Diat.barcode reference database
- [`download_ksgp_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ksgp_db.md)
  : Download the KSGP or GTDB+ reference database
- [`download_ltplus_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ltplus_db.md)
  : Download the LTPlus reference database
- [`download_marjaam_db()`](https://adrientaudiere.github.io/dbpq/reference/download_marjaam_db.md)
  : Download the MaarjAM reference database
- [`download_eukaryome_db()`](https://adrientaudiere.github.io/dbpq/reference/download_eukaryome_db.md)
  : Download the Eukaryome reference database

## Format taxonomy headers

Convert between taxonomy header formats (SINTAX, UNITE, Greengenes2,
dada2).

- [`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md)
  : Convert a FASTA database to a specified taxonomy format
- [`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md)
  : Format taxonomy headers for dada2::assignTaxonomy
- [`format2dada2_species()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2_species.md)
  : Format taxonomy headers for dada2::addSpecies
- [`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md)
  : Format taxonomy headers to SINTAX format

## Summarize databases

Describe and explore database contents.

- [`count_seq_db()`](https://adrientaudiere.github.io/dbpq/reference/count_seq_db.md)
  : Count sequences in a FASTA file
- [`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md)
  : Count lines matching a pattern in a FASTA file
- [`count_unwanted_tax()`](https://adrientaudiere.github.io/dbpq/reference/count_unwanted_tax.md)
  : Count unwanted values in a taxonomy table
- [`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
  : List and count taxonomic ranks from a FASTA database
- [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
  : Summarize a FASTA reference database

## Taxonomic assignment

Assign taxonomy to sequences.

- [`add_sh_to_taxonomy()`](https://adrientaudiere.github.io/dbpq/reference/add_sh_to_taxonomy.md)
  **\[experimental\]** : Annotate query sequences with UNITE Species
  Hypothesis (SH) names

## Modify databases

Filter, trim, and transform FASTA databases.

- [`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md)
  : Filter a FASTA database by taxonomic pattern
- [`cutadapt_rm_primers_db()`](https://adrientaudiere.github.io/dbpq/reference/cutadapt_rm_primers_db.md)
  : Remove primers from a FASTA database using cutadapt

## Utilities

Helper functions.

- [`get_file_extension()`](https://adrientaudiere.github.io/dbpq/reference/get_file_extension.md)
  : Get file extension(s)
- [`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md)
  : Get rank information for a taxonomy format
- [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)
  : Detect taxonomy format from FASTA headers
- [`is_vsearch_installed()`](https://adrientaudiere.github.io/dbpq/reference/is_vsearch_installed.md)
  : Check whether vsearch is installed
- [`find_vsearch()`](https://adrientaudiere.github.io/dbpq/reference/find_vsearch.md)
  : Find the vsearch executable
