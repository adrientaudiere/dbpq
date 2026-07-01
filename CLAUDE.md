# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

**dbpq** is an R package for managing FASTA reference databases used in taxonomic assignment for metabarcoding. It provides tools to download, format, summarize, and modify databases. Part of the pqverse ecosystem.

## Common Commands

```bash
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
|--------|---------|
| `dbpq-package.R` | Package documentation and imports |
| `utils.R` | Internal helpers (is_gzipped, read_lines_db, get_file_extension) |
| `download.R` | download_*_db() functions for major databases |
| `format.R` | format2dada2(), format2sintax(), format2dada2_species() |
| `summarize.R` | count_seq_db(), count_pattern_db(), list_ranks_db(), summarize_db() |
| `modify.R` | filter_db(), cutadapt_rm_primers_db() |

### Function Naming Convention

- `{verb}_db()` for actions on databases (e.g., `filter_db()`, `summarize_db()`)
- `{verb}_{what}_db()` for specific operations (e.g., `count_pattern_db()`, `count_seq_db()`)
- `download_{source}_db()` for download functions
- `format2{target}()` for format conversion functions

### Design Principles

- Accept both plain and gzip FASTA files throughout
- Silent by default, `verbose = TRUE` for messages
- No dependency on MiscMetabar (standalone package)
- Use Biostrings for FASTA I/O

## Coding Conventions

- Use base pipe (`|>`) not magrittr (`%>%`)
- Use `\() ...` for single-line anonymous functions, `function() {...}` otherwise
- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`

## Agent skills

### Issue tracker

Issues and PRDs are tracked as GitHub issues via the `gh` CLI; external PRs are not a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the five canonical triage labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
