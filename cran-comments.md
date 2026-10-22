## First submission

This is the first submission of dbpq to CRAN.

## R CMD check results

0 errors | 0 warnings | 1 note

* "New submission", and "Version contains large components (0.2.0.9000)"
  on the development version; the latter disappears with the release.

## Examples in \dontrun{}

The `download_*_db()` functions download reference databases of tens to
hundreds of MB from the providers' servers, and `cutadapt_rm_primers_db()` /
`add_sh_to_taxonomy()` need such a downloaded database plus external software
(cutadapt, vsearch). Their examples are in `\dontrun{}` because they cannot
run without these files and must not trigger large downloads. All other
examples run on the small FASTA files shipped in `inst/extdata`.

## Method References

There are no published references describing the methods in this package.
The package provides utilities for downloading, formatting, summarizing, and
modifying FASTA reference databases used in metabarcoding pipelines.

## Test environments

* local Linux (Pop!_OS 24.04), R 4.6.1, `R CMD check --as-cran --run-donttest`
  against the CRAN version of 'MiscMetabar' (0.16.8), 2026-10-22.
