```markdown
# dbpq Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches the core development patterns and workflows used in the `dbpq` repository, a JavaScript codebase (no framework detected) focused on taxonomic database utilities. You'll learn about the project's coding conventions, how to add new features or utilities, update documentation, expand test coverage, and the commands that streamline these processes.

## Coding Conventions

- **File Naming:**  
  Uses `snake_case` for file names.  
  *Example:*  
  ```
  database_utils.js
  format_conversion.js
  ```

- **Import Style:**  
  Uses relative imports.  
  *Example:*  
  ```js
  import { parseTaxonomy } from './taxonomy_parser.js';
  ```

- **Export Style:**  
  Uses named exports.  
  *Example:*  
  ```js
  export function summarizeDatabase(db) { ... }
  export { summarizeDatabase, annotateEntries };
  ```

- **Commit Messages:**  
  - Mixed types, often prefixed with `feat`, `refactor`, or `fix`.
  - Average length: ~50 characters.
  *Example:*  
  ```
  feat: add support for new taxonomy format
  fix: correct parsing of database headers
  refactor: streamline download logic
  ```

## Workflows

### Add New Database Download Function
**Trigger:** When someone wants to support downloading a new reference database.  
**Command:** `/add-database-download`

1. Add the new function to `R/download.R`.
2. Update `DESCRIPTION` and/or `NAMESPACE` as needed.
3. Add corresponding documentation in `man/download_*.Rd`.
4. Update or add tests in `tests/testthat/test-download.R`.
5. Update `README.md` if needed.

*Example function addition:*
```js
export function downloadNewTaxDb(url, dest) {
  // logic to download and validate the database
}
```

---

### Add New Analysis or Utility Function
**Trigger:** When someone wants to provide a new analysis, summary, or utility for databases.  
**Command:** `/add-analysis-function`

1. Add the new function to the appropriate `R/*.R` file (e.g., `R/summarize.R`).
2. Update `NAMESPACE` and `NEWS.md`.
3. Add or update documentation in `man/*.Rd`.
4. Add or update tests in `tests/testthat/`.
5. Update `_pkgdown.yml` if needed.

*Example:*
```js
export function summarizeEntries(entries) {
  // logic to summarize database entries
}
```

---

### Add or Update Format Conversion
**Trigger:** When someone wants to add or improve format conversion utilities.  
**Command:** `/add-format-conversion`

1. Add or update the function in `R/format.R`.
2. Update `NAMESPACE` and `NEWS.md`.
3. Add or update documentation in `man/format*.Rd`.
4. Add or update tests in `tests/testthat/test-format.R`.
5. Update or add `vignettes/taxonomy-formats.Rmd`.

*Example:*
```js
export function convertToNCBIFormat(data) {
  // conversion logic
}
```

---

### Add or Update Documentation and README
**Trigger:** When someone wants to improve user-facing documentation.  
**Command:** `/update-docs`

1. Edit `README.md` and/or `README.html`.
2. Edit or add vignettes or docs/articles.
3. Update `man/figures` or logo if needed.

---

### Add or Update Test Suites
**Trigger:** When someone wants to ensure new or existing features are robust.  
**Command:** `/add-tests`

1. Add new test files or update existing ones in `tests/testthat/`.
2. Add or update fixtures in `tests/testthat/fixtures/`.
3. Update `NEWS.md` if relevant.

*Example test file:*
```js
// tests/testthat/test-summarize.js
import { summarizeEntries } from '../../src/summarize_entries.js';

test('summarizeEntries returns correct summary', () => {
  // test logic
});
```

## Testing Patterns

- **Test Framework:** Unknown (pattern: `*.test.ts`), but tests are colocated in `tests/testthat/`.
- **Test File Naming:**  
  Test files use the pattern `test-*.R` (or `*.test.ts` in JS/TS).
- **Fixtures:**  
  Test fixtures are stored in `tests/testthat/fixtures/`.
- **Helpers:**  
  Helper scripts may be included as `helper-*.R`.

*Example test invocation:*
```js
// Example in JavaScript/TypeScript
import { convertToNCBIFormat } from '../format_conversion.js';

test('convertToNCBIFormat handles empty input', () => {
  expect(convertToNCBIFormat([])).toEqual([]);
});
```

## Commands

| Command                  | Purpose                                                     |
|--------------------------|-------------------------------------------------------------|
| /add-database-download   | Add a new database download function with docs and tests     |
| /add-analysis-function   | Add a new analysis or utility function                      |
| /add-format-conversion   | Add or update format conversion utilities                   |
| /update-docs             | Update documentation, README, or vignettes                  |
| /add-tests               | Add or update test suites and fixtures                      |
```
