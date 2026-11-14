## First submission

This is the first submission of dbpq to CRAN.

## R CMD check results

0 errors | 0 warnings | 1 note

* "New submission", and "Version contains large components (0.2.0.9000)"
  on the development version; the latter disappears with the release.

## Examples in \dontrun{}

Only the 12 `download_*_db()` functions keep a `\dontrun{}` block: they
download reference databases of tens to hundreds of MB from the providers'
servers, which examples must not trigger. `download_midori2_db()` and
`download_eukaryome_db()` also run a plain example (without `url`, they only
print where to find the download link). `add_sh_to_taxonomy()` needs vsearch,
so its example is in `@examplesIf is_vsearch_installed()`;
`cutadapt_rm_primers_db()` runs with `cmd_is_run = FALSE`, which only builds
the cutadapt command. All other examples run on the small FASTA files
shipped in `inst/extdata`.

## Method References

There are no published references describing the methods in this package.
The package provides utilities for downloading, formatting, summarizing, and
modifying FASTA reference databases used in metabarcoding pipelines.

## Test environments

* local Linux (Pop!_OS 24.04), R 4.6.1, `R CMD check --as-cran --run-donttest`
  against the CRAN version of 'MiscMetabar' (0.16.8), 2026-10-22.
* win-builder R-devel (Windows Server 2022, 2026-10-22): 1 note (new
  submission; possibly misspelled technical words in DESCRIPTION).
