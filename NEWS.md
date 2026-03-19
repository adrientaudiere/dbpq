# dbpq 0.1

* Initial development version.
* `detect_tax_format()` auto-detects taxonomy format (`"default"`, `"sintax"`, `"greengenes2"`) from FASTA headers.
* `download_diatbarcode_db()` downloads the Diat.barcode rbcL reference database for diatoms.
* `download_eukaryome_db()` now lists the SINTAX format download page (<https://eukaryome.org/sintax/>) in its instructions.
* `download_greengenes2_db()` downloads the Greengenes2 16S rRNA database (dada2 format from Zenodo or plain FASTA from FTP).
* `download_midori2_db()` downloads the MIDORI2 mitochondrial reference database for COI and other markers.
* `download_pr2_db()` now accepts `format = "sintax"` as an alias for `"UTAX"`. Documentation now mentions the [pr2database](https://pr2database.github.io/pr2database/) R package as a complementary tool.
* `download_rdp_db()` downloads the RDP 16S rRNA database (dada2-formatted training sets from Zenodo).
* `download_unite_db()` gains a `taxonomic_format` parameter (`"default"` or `"sintax"`) to download SINTAX-formatted FASTA files directly, ready for use with `vsearch --sintax`.
* `list_ranks_db()` and `summarize_db()` gain a `tax_format` parameter to handle different taxonomy header formats (`"unite"`, `"sintax"`, `"greengenes2"`, `"pr2"`, or `"auto"`). `list_ranks_db()` also gains a `rank_position` parameter for positional (prefix-less) taxonomy headers.
* `tax_prefixes()` returns the rank prefixes for a given taxonomy format, for use with `list_ranks_db()` and `summarize_db()`.
* `count_pattern_db()` counts sequences matching a pattern in FASTA files.
* `count_seq_db()` counts total sequences in a FASTA file.
* `filter_db()` filters a FASTA database by taxonomic pattern.
* `format_fasta_db()` is a new unified function to convert FASTA taxonomy headers between any supported format (`"sintax"`, `"unite"`, `"greengenes2"`, `"dada2"`, `"dada2_species"`), with auto-detection of the input format.
* `format2dada2()`, `format2dada2_species()`, and `format2sintax()` now accept an `input_format` argument (`"auto"`, `"sintax"`, `"unite"`, `"greengenes2"`) instead of `from_sintax`, and all support Greengenes2 as an additional input format. They are now wrappers around `format_fasta_db()`.
* `cutadapt_rm_primers_db()` removes primer sequences from a FASTA database using cutadapt.
