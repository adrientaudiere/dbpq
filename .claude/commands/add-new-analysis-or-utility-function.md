---
name: add-new-analysis-or-utility-function
description: Workflow command scaffold for add-new-analysis-or-utility-function in dbpq.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-new-analysis-or-utility-function

Use this workflow when working on **add-new-analysis-or-utility-function** in `dbpq`.

## Goal

Adds a new analysis or utility function (e.g., summarize, annotate, diagnose, profile), with documentation and tests.

## Common Files

- `R/*.R`
- `NAMESPACE`
- `NEWS.md`
- `man/*.Rd`
- `tests/testthat/test-*.R`
- `_pkgdown.yml`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Add new function to appropriate R/*.R file (e.g., R/summarize.R, R/annotate.R, R/diagnose.R, R/profile.R)
- Update NAMESPACE and NEWS.md
- Add or update man/*.Rd documentation
- Add or update tests in tests/testthat/
- Update _pkgdown.yml if needed

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.