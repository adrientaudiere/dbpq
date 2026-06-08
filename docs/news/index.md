# Changelog

## dbpq (development version)

- Download functions now produce FASTA files with taxonomy in the
  headers, ready for
  [`MiscMetabar::add_new_taxonomy_pq()`](https://adrientaudiere.github.io/MiscMetabar/reference/add_new_taxonomy_pq.html),
  via a `tax_format` argument (`"dada2"`/`"sintax"`).
  [`download_greengenes2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_greengenes2_db.md)
  strips its `d__`/`p__` prefixes to plain dada2 (the prefixed form was
  rejected by `assignTaxonomy()`);
  [`download_ksgp_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ksgp_db.md)
  merges its companion `.tax` into the headers by sequence ID;
  [`download_ltplus_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ltplus_db.md)
  merges its taxonomy CSV;
  [`download_marjaam_db()`](https://adrientaudiere.github.io/dbpq/reference/download_marjaam_db.md)
  uses the QIIME release (FASTA + taxonomy table); and
  [`download_bold_db()`](https://adrientaudiere.github.io/dbpq/reference/download_bold_db.md)
  pulls full ranked taxonomy from BOLD’s `combined` endpoint.

- [`download_marjaam_db()`](https://adrientaudiere.github.io/dbpq/reference/download_marjaam_db.md)
  now downloads the current MaarjAM QIIME release (a `dataset` argument
  selects `"SSU"` (default), `"SSU_TYPE"`, `"LSU"`, `"full_ITS"` or
  `"onlyITS"`); the previous default URL had stopped working.

- [`download_bold_db()`](https://adrientaudiere.github.io/dbpq/reference/download_bold_db.md)
  queries the still-available `v3.boldsystems.org` API over HTTPS and,
  by default, returns sequences for the requested `marker` with full
  ranked-taxonomy headers (BOLD’s main site has migrated to v5; the
  `combined` endpoint remains accessible).

- New article *How reference databases relate* documents the
  sequence-derivation (nestedness) and taxonomic-coverage relationships
  between supported databases as an interactive network and two
  adjacency/coverage matrices, with every derivation edge sourced from
  the describing paper. Corrects the README diagram: EUKARYOME
  incorporates SILVA, PR2 and UNITE (it is not independent), and
  Greengenes2 derives from GTDB r207 directly (sharing the Karst 2018
  source with KSGP).

- New function
  [`download_ltplus_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ltplus_db.md)
  downloads the LTPlus 16S rRNA reference FASTA for Bacteria and
  Archaea, which extends the All-Species Living Tree Project (LTP) with
  best-quality non-type sequences from SILVA, GTDB and NCBI (98.7%
  identity clustering). The (unaligned) FASTA is fetched directly from
  the LTP release server and, by default (`to_dna = TRUE`), transcribed
  from RNA to a clean DNA FASTA. By default (`tax_format = "dada2"`) it
  also merges the companion taxonomy CSV into the headers (100% of
  sequences annotated), so the file feeds dada2/VSEARCH and
  `add_new_taxonomy_pq()` directly; a `url` parameter selects other
  releases (Rosselló-Móra et al. 2026, ).

- New function
  [`download_ksgp_db()`](https://adrientaudiere.github.io/dbpq/reference/download_ksgp_db.md)
  downloads the KSGP (Karst, Silva, GTDB, and PR2) SSU reference
  database and its GTDB+ and GTDB_cleaned components. Supports three
  annotation variants (`"sintax"`, `"lca"`, `"ksgp_plus"`) and a
  complete archive download. KSGP is optimized for Archaea taxonomic
  assignment, improving Class and Order assignments 2.7x and 4.2x over
  SILVA (Grant et al. 2025, ).

- [`download_silva_db()`](https://adrientaudiere.github.io/dbpq/reference/download_silva_db.md)
  gains `format = "sintax"`, which downloads the official arb-silva
  DADA2 `toSpecies` trainset and converts it locally to a
  VSEARCH/USEARCH SINTAX database (7 ranks `d,p,c,o,f,g,s`, written as
  `*_sintax.fasta.gz`). Synthetic sequence labels
  (`SILVA<version>_<target>_NNNNNN`) are generated because the dada2
  trainset carries no accession.

- [`download_silva_db()`](https://adrientaudiere.github.io/dbpq/reference/download_silva_db.md)
  now sources the dada2-formatted files from the official arb-silva
  DADA2 release instead of Zenodo, and supports `target = "LSU"` for the
  `dada2`, `dada2_species`, and `sintax` formats (previously SSU only).

- [`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md)
  and
  [`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md)
  accept `input_format = "dada2"` (positional, prefix-less taxonomy) and
  gain an `id_prefix` argument to label records that carry no sequence
  ID.

- [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)
  now recognises positional dada2 headers (returns `"dada2"`) instead of
  falling through to `"unknown"`.

- New function
  [`add_sh_to_taxonomy()`](https://adrientaudiere.github.io/dbpq/reference/add_sh_to_taxonomy.md)
  (marked experimental) annotates query sequences with UNITE Species
  Hypothesis (SH) names by running `vsearch --usearch_global` against a
  UNITE reference database and extracting SH identifiers from matched
  sequence headers. Detects ambiguous assignments when multiple top hits
  disagree on the SH name. Ports the logic of the nf-core/ampliseq
  `add_sh_to_taxonomy.py` script into R.

- [`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md)
  and
  [`count_seq_db()`](https://adrientaudiere.github.io/dbpq/reference/count_seq_db.md)
  no longer emit a spurious warning when the pattern has zero matches
  (for example when counting sequences in an empty file).

- [`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md)
  and
  [`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md)
  now quote file paths and search patterns passed to shell commands, so
  paths or patterns containing spaces or shell metacharacters are
  handled correctly.

- New function
  [`find_vsearch()`](https://adrientaudiere.github.io/dbpq/reference/find_vsearch.md)
  locates the vsearch executable on the system PATH or verifies a
  user-supplied path.

- New function
  [`is_vsearch_installed()`](https://adrientaudiere.github.io/dbpq/reference/is_vsearch_installed.md)
  checks whether vsearch is available on the system.

- [`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
  now emits an informative message when no taxa match the requested rank
  prefix, suggesting
  [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)
  to identify the file’s taxonomy format.

- [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
  now handles empty FASTA databases gracefully, reporting zero sequences
  instead of emitting warnings and `Inf` length statistics.

## dbpq 0.1

- Initial development version.
- [`cutadapt_rm_primers_db()`](https://adrientaudiere.github.io/dbpq/reference/cutadapt_rm_primers_db.md)
  now checks the exit code of cutadapt and stops with an informative
  error when the binary is missing or fails, instead of silently
  continuing.
- [`download_unite_db()`](https://adrientaudiere.github.io/dbpq/reference/download_unite_db.md)
  now emits a message when `type = "static"` and `taxon_group = "fungi"`
  to clarify that UNITE v10.0 does not ship separate static/dynamic
  archives for fungi.
- [`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md)
  documentation now has a runnable example using the bundled
  `example_unite.fasta` file.
- [`get_file_extension()`](https://adrientaudiere.github.io/dbpq/reference/get_file_extension.md)
  no longer emits a spurious warning for double-extension files
  (e.g. `.fasta.gz`), which are the standard format for compressed
  databases.
- An example FASTA file (`inst/extdata/example_unite.fasta`, 5 sequences
  in UNITE format) is now bundled with the package, enabling runnable
  examples for
  [`count_seq_db()`](https://adrientaudiere.github.io/dbpq/reference/count_seq_db.md),
  [`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md),
  [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md),
  [`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md),
  [`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md),
  and
  [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md).
- `tax_prefixes("sintax")` documentation now clarifies that UNITE SINTAX
  files use `k:` (kingdom) as their first rank and do not include a `d:`
  (domain) level; a `d: 0 sequences` row in
  [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
  output is therefore expected.
- [`detect_tax_format()`](https://adrientaudiere.github.io/dbpq/reference/detect_tax_format.md)
  auto-detects taxonomy format (`"default"`, `"sintax"`,
  `"greengenes2"`) from FASTA headers.
- [`download_diatbarcode_db()`](https://adrientaudiere.github.io/dbpq/reference/download_diatbarcode_db.md)
  downloads the Diat.barcode rbcL reference database for diatoms.
- [`download_eukaryome_db()`](https://adrientaudiere.github.io/dbpq/reference/download_eukaryome_db.md)
  now lists the SINTAX format download page
  (<https://eukaryome.org/sintax/>) in its instructions.
- [`download_greengenes2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_greengenes2_db.md)
  downloads the Greengenes2 16S rRNA database (dada2 format from Zenodo
  or plain FASTA from FTP).
- [`download_midori2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_midori2_db.md)
  downloads the MIDORI2 mitochondrial reference database for COI and
  other markers.
- [`download_pr2_db()`](https://adrientaudiere.github.io/dbpq/reference/download_pr2_db.md)
  now accepts `format = "sintax"` as an alias for `"UTAX"`.
  Documentation now mentions the
  [pr2database](https://pr2database.github.io/pr2database/) R package as
  a complementary tool.
- [`download_rdp_db()`](https://adrientaudiere.github.io/dbpq/reference/download_rdp_db.md)
  downloads the RDP 16S rRNA database (dada2-formatted training sets
  from Zenodo).
- [`download_unite_db()`](https://adrientaudiere.github.io/dbpq/reference/download_unite_db.md)
  gains a `taxonomic_format` parameter (`"default"` or `"sintax"`) to
  download SINTAX-formatted FASTA files directly, ready for use with
  `vsearch --sintax`.
- [`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
  and
  [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md)
  gain a `tax_format` parameter to handle different taxonomy header
  formats (`"unite"`, `"sintax"`, `"greengenes2"`, `"pr2"`, or
  `"auto"`).
  [`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
  also gains a `rank_position` parameter for positional (prefix-less)
  taxonomy headers.
- [`tax_prefixes()`](https://adrientaudiere.github.io/dbpq/reference/tax_prefixes.md)
  returns the rank prefixes for a given taxonomy format, for use with
  [`list_ranks_db()`](https://adrientaudiere.github.io/dbpq/reference/list_ranks_db.md)
  and
  [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md).
- [`count_unwanted_tax()`](https://adrientaudiere.github.io/dbpq/reference/count_unwanted_tax.md)
  scans a taxonomy table (from a phyloseq object or a FASTA reference
  database) for common problematic values such as `"unclassified"`,
  `"unknown"`, `"Incertae_sedis"`, NA-like strings, and empty
  QIIME-style rank prefixes. Returns a tibble summarising matches per
  pattern and rank. Suggests
  [`MiscMetabar::verify_tax_table()`](https://adrientaudiere.github.io/MiscMetabar/reference/verify_tax_table.html)
  for cleaning when the input is a phyloseq object. Default patterns are
  sourced from
  [`MiscMetabar::unwanted_tax_patterns`](https://adrientaudiere.github.io/MiscMetabar/reference/unwanted_tax_patterns.html)
  when MiscMetabar is installed, with a built-in fallback otherwise.
- [`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md)
  counts sequences matching a pattern in FASTA files.
- [`count_seq_db()`](https://adrientaudiere.github.io/dbpq/reference/count_seq_db.md)
  counts total sequences in a FASTA file.
- [`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md)
  filters a FASTA database by taxonomic pattern.
- [`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md)
  is a new unified function to convert FASTA taxonomy headers between
  any supported format (`"sintax"`, `"unite"`, `"greengenes2"`,
  `"dada2"`, `"dada2_species"`), with auto-detection of the input
  format.
- [`format2dada2()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2.md),
  [`format2dada2_species()`](https://adrientaudiere.github.io/dbpq/reference/format2dada2_species.md),
  and
  [`format2sintax()`](https://adrientaudiere.github.io/dbpq/reference/format2sintax.md)
  now accept an `input_format` argument (`"auto"`, `"sintax"`,
  `"unite"`, `"greengenes2"`) instead of `from_sintax`, and all support
  Greengenes2 as an additional input format. They are now wrappers
  around
  [`format_fasta_db()`](https://adrientaudiere.github.io/dbpq/reference/format_fasta_db.md).
- [`cutadapt_rm_primers_db()`](https://adrientaudiere.github.io/dbpq/reference/cutadapt_rm_primers_db.md)
  removes primer sequences from a FASTA database using cutadapt.
