# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Package Overview

**dbpq** is an R package for managing FASTA reference databases used in
taxonomic assignment for metabarcoding. It provides tools to download,
format, summarize, and modify databases. Part of the pqverse ecosystem.

## Common Commands

``` bash
# Run code with loaded package
Rscript -e "devtools::load_all(); code"

# Run all tests
Rscript -e "devtools::test()"

# Run tests for files starting with {name}
Rscript -e "devtools::test(filter = '^{name}')"

# Run tests for R/{name}.R
Rscript -e "devtools::test_active_file('R/{name}.R')"

# Generate documentation
Rscript -e "devtools::document()"

# Full package check
Rscript -e "devtools::check()"
```

## Architecture

### Key Modules

| Module | Purpose |
|----|----|
| `dbpq-package.R` | Package documentation and imports |
| `utils.R` | Internal helpers (is_gzipped, read_lines_db, get_file_extension) |
| `download.R` | download\_\*\_db() functions for major databases |
| `format.R` | format2dada2(), format2sintax(), format2dada2_species() |
| `summarize.R` | count_seq_db(), count_pattern_db(), list_ranks_db(), summarize_db() |
| `modify.R` | filter_db(), cutadapt_rm_primers_db() |

### Function Naming Convention

- `{verb}_db()` for actions on databases (e.g.,
  [`filter_db()`](https://adrientaudiere.github.io/dbpq/reference/filter_db.md),
  [`summarize_db()`](https://adrientaudiere.github.io/dbpq/reference/summarize_db.md))
- `{verb}_{what}_db()` for specific operations (e.g.,
  [`count_pattern_db()`](https://adrientaudiere.github.io/dbpq/reference/count_pattern_db.md),
  [`count_seq_db()`](https://adrientaudiere.github.io/dbpq/reference/count_seq_db.md))
- `download_{source}_db()` for download functions
- `format2{target}()` for format conversion functions

### Design Principles

- Accept both plain and gzip FASTA files throughout
- Silent by default, `verbose = TRUE` for messages
- No dependency on MiscMetabar (standalone package)
- Use Biostrings for FASTA I/O

## Coding Conventions

- Use base pipe (`|>`) not magrittr (`%>%`)
- Use `\() ...` for single-line anonymous functions, `function() {...}`
  otherwise
- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`
