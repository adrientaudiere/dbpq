---
name: add-new-database-download-function
description: Workflow command scaffold for add-new-database-download-function in dbpq.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-new-database-download-function

Use this workflow when working on **add-new-database-download-function** in `dbpq`.

## Goal

Implements a new function to download a specific taxonomic database, including documentation and tests.

## Common Files

- `R/download.R`
- `DESCRIPTION`
- `NAMESPACE`
- `man/download_*.Rd`
- `tests/testthat/test-download.R`
- `README.md`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Add new function to R/download.R
- Update DESCRIPTION and/or NAMESPACE
- Add corresponding man/*.Rd documentation file
- Update or add tests in tests/testthat/test-download.R
- Update README.md if needed

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.