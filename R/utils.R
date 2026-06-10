# ——————————————————————————————————————————————————————————————————————
# Taxonomy format helpers
# ——————————————————————————————————————————————————————————————————————

#' Get rank information for a taxonomy format
#'
#' @description
#' Returns the taxonomic rank information for common reference database
#' formats. For prefix-based formats (unite, sintax, greengenes2), returns
#' a named character vector of prefixes. For positional formats (pr2),
#' returns a named integer vector of rank positions.
#'
#' Use the result with [list_ranks_db()] and [summarize_db()] via their
#' `tax_format` parameter.
#'
#' Note: `dada2::assignTaxonomy()` is a classifier, not a taxonomy format.
#' It accepts any semicolon-separated taxonomy with any number of levels,
#' regardless of whether prefixes are present or not. Use the `taxLevels`
#' argument in `dada2::assignTaxonomy()` to specify the rank names.
#'
#' @param tax_format (Character) One of:
#'   - `"unite"`: `k__`/`p__`/... format used by UNITE general FASTA
#'     releases.
#'   - `"sintax"`: `d:`/`k:`/`p:`/... format used by VSEARCH SINTAX and
#'     USEARCH UTAX databases (UNITE SINTAX, PR2 UTAX). Note that UNITE
#'     SINTAX files use `k:` (kingdom) as their first rank and do not
#'     include `d:` (domain). When calling [summarize_db()] on a UNITE
#'     SINTAX file, the `d:` row will show 0 sequences — this is expected.
#'   - `"greengenes2"`: `d__`/`p__`/... format used by Greengenes2 (starts
#'     with domain `d__` instead of kingdom `k__`).
#'   - `"pr2"`: positional format with 9 levels specific to protist
#'     taxonomy: Domain, Supergroup, Division, Subdivision, Class, Order,
#'     Family, Genus, Species.
#'
#' @returns For prefix-based formats: a named character vector of rank
#'   prefixes. For positional formats: a named integer vector of rank
#'   positions.
#' @export
#' @seealso [list_ranks_db()], [summarize_db()], [detect_tax_format()]
#' @examples
#' tax_prefixes("unite")
#' tax_prefixes("sintax")
#' tax_prefixes("greengenes2")
#' tax_prefixes("pr2")
tax_prefixes <- function(
  tax_format = c("unite", "sintax", "greengenes2", "pr2")
) {
  tax_format <- match.arg(tax_format)
  switch(
    tax_format,
    unite = c(
      k = "k__",
      p = "p__",
      c = "c__",
      o = "o__",
      f = "f__",
      g = "g__",
      s = "s__"
    ),
    sintax = c(
      d = "d:",
      k = "k:",
      p = "p:",
      c = "c:",
      o = "o:",
      f = "f:",
      g = "g:",
      s = "s:"
    ),
    greengenes2 = c(
      d = "d__",
      p = "p__",
      c = "c__",
      o = "o__",
      f = "f__",
      g = "g__",
      s = "s__"
    ),
    pr2 = c(
      Domain = 1L,
      Supergroup = 2L,
      Division = 3L,
      Subdivision = 4L,
      Class = 5L,
      Order = 6L,
      Family = 7L,
      Genus = 8L,
      Species = 9L
    )
  )
}


#' Detect taxonomy format from FASTA headers
#'
#' @description
#' Reads a few sequence headers from a FASTA file and guesses the
#' taxonomy format based on characteristic patterns.
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param n_headers (Integer, default `20`) Number of headers to inspect.
#'
#' @returns A character string: one of `"unite"`, `"sintax"`,
#'   `"greengenes2"`, `"pr2"`, or `"unknown"`.
#' @export
#' @seealso [tax_prefixes()], [list_ranks_db()], [summarize_db()]
#' @examples
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' detect_tax_format(db)
detect_tax_format <- function(file, n_headers = 20L) {
  lines <- read_lines_db(file)
  headers <- lines[grepl("^>", lines)]
  detect_tax_format_from_headers(headers, n_headers = n_headers)
}


#' Detect taxonomy format from a vector of FASTA headers
#'
#' @description
#' Header-based core of [detect_tax_format()]. Operates on an in-memory
#' character vector of header lines so callers that already hold the headers
#' (e.g. [diagnose_db()]) need not re-read the file.
#'
#' @param headers (Character vector) FASTA header lines (with or without the
#'   leading `>`).
#' @param n_headers (Integer, default `20`) Number of headers to inspect.
#'
#' @returns A character string: one of `"unite"`, `"sintax"`,
#'   `"greengenes2"`, `"pr2"`, `"dada2"`, or `"unknown"`.
#' @keywords internal
detect_tax_format_from_headers <- function(headers, n_headers = 20L) {
  headers <- utils::head(headers, n_headers)

  if (length(headers) == 0) {
    return("unknown")
  }

  sample_text <- paste(headers, collapse = " ")

  # SINTAX: headers contain "tax=" followed by single-letter:value pairs
  if (grepl("tax=", sample_text, fixed = TRUE)) {
    return("sintax")
  }

  # Greengenes2: uses d__ for domain (not k__)
  if (grepl("d__", sample_text, fixed = TRUE)) {
    return("greengenes2")
  }

  # UNITE: uses k__ for kingdom
  if (grepl("k__", sample_text, fixed = TRUE)) {
    return("unite")
  }

  # Positional formats: count semicolons and look for known patterns
  # PR2 dada2 format has 9 levels, standard dada2 has ~6
  # PR2 supergroups: Amorphea, TSAR, Archaeplastida, Excavata, etc.
  pr2_supergroups <- c(
    "Amorphea",
    "TSAR",
    "Archaeplastida",
    "Excavata",
    "Cryptista",
    "Haptista",
    "Provora",
    "Stramenopiles",
    "Alveolata",
    "Rhizaria",
    "Opisthokonta",
    "Amoebozoa"
  )
  pr2_pattern <- paste(pr2_supergroups, collapse = "|")
  if (grepl(pr2_pattern, sample_text)) {
    return("pr2")
  }

  # Positional, prefix-less, semicolon-delimited taxonomy (e.g. dada2
  # assignTaxonomy training sets). Falls here only after the labelled and
  # pr2-keyword checks above have failed.
  if (grepl(";", sample_text, fixed = TRUE)) {
    return("dada2")
  }

  "unknown"
}


# ——————————————————————————————————————————————————————————————————————
# Internal: extract ranks by position from FASTA headers
# ——————————————————————————————————————————————————————————————————————

#' Extract a taxonomic rank by position from FASTA headers
#'
#' @param headers Character vector of FASTA header lines.
#' @param position Integer, the 1-based position of the rank in the
#'   semicolon-delimited taxonomy string.
#' @param sep Character, delimiter between ranks (default `";"`).
#'
#' @returns A character vector of extracted rank values (NA where missing).
#' @keywords internal
extract_rank_by_position <- function(headers, position, sep = ";") {
  # Remove leading > and any ID before the taxonomy
  # For dada2 format: ">Kingdom;Phylum;..." or ">ID Kingdom;Phylum;..."
  # For PR2 format: ">ID_U Domain;Supergroup;..."
  vapply(
    headers,
    \(h) {
      # Remove leading >
      h <- sub("^>", "", h)
      # Split by spaces to separate ID from taxonomy
      parts <- strsplit(h, "\\s+")[[1]]
      # Try to find the part with semicolons (taxonomy string)
      tax_part <- NULL
      for (p in parts) {
        if (grepl(sep, p, fixed = TRUE)) {
          tax_part <- p
          break
        }
      }
      # If no semicolons found, the whole header might be taxonomy
      if (is.null(tax_part)) {
        tax_part <- h
      }
      ranks <- strsplit(tax_part, sep, fixed = TRUE)[[1]]
      # Remove empty trailing elements
      ranks <- ranks[nzchar(ranks)]
      if (length(ranks) >= position) {
        ranks[[position]]
      } else {
        NA_character_
      }
    },
    character(1),
    USE.NAMES = FALSE
  )
}


#' Check if a file is gzipped
#'
#' @param file_path (Character, required) Path to a file.
#'
#' @returns Logical, TRUE if the file is gzipped.
#' @keywords internal
is_gzipped <- function(file_path) {
  con <- file(file_path[[1]])
  on.exit(close(con))
  summary(con)$class == "gzfile"
}


#' Get file extension(s)
#'
#' @description
#' Returns all extensions from a file name. Double extensions such as
#' `.fasta.gz` are treated as a first-class case and returned as a two-element
#' vector (e.g. `c("fasta", "gz")`).
#'
#' @param file_path (Character, required) Path to a file.
#'
#' @returns A character vector of file extensions (one element per extension).
#' @export
#' @examples
#' get_file_extension("my_database.fasta")
#' get_file_extension("my_database.fasta.gz")
get_file_extension <- function(file_path) {
  if (stringr::str_count(basename(file_path), "\\.") == 0) {
    stop("No file extension found in: ", file_path)
  }
  strsplit(basename(file_path), ".", fixed = TRUE)[[1]][-1]
}


#' Read lines from a plain or gzipped file
#'
#' @param file_path (Character, required) Path to a file (plain or gzip).
#'
#' @returns A character vector of lines.
#' @keywords internal
read_lines_db <- function(file_path) {
  if (is_gzipped(file_path)) {
    con <- gzfile(normalizePath(file_path), open = "r")
  } else {
    con <- file(normalizePath(file_path), open = "r")
  }
  on.exit(close(con))
  readLines(con)
}


# ——————————————————————————————————————————————————————————————————————
# Unwanted taxonomy patterns
# ——————————————————————————————————————————————————————————————————————

#' Get the default unwanted taxonomy patterns
#'
#' Returns `MiscMetabar::unwanted_tax_patterns` when MiscMetabar is
#' installed, otherwise falls back to a built-in copy of the same
#' named character vector.
#'
#' @returns A named character vector (names = descriptions,
#'   values = regex patterns).
#' @keywords internal
unwanted_tax_patterns_default <- function() {
  if (requireNamespace("MiscMetabar", quietly = TRUE)) {
    return(MiscMetabar::unwanted_tax_patterns)
  }
  # Built-in fallback (kept in sync with MiscMetabar)
  c(
  "NA-like (NA, NaN, nan)" = "^[Nn][Aa][Nn]?$",
  "NA-like (N/A, n/a)" = "^[Nn]/[Aa]$",
  "None / none" = "^[Nn]one$",
  "empty string" = "^$",
  "whitespace only" = "^\\s+$",
  "question mark" = "^\\?$",
  "unclassified" = "[Uu]nclassified",
  "unknown" = "[Uu]nknown",
  "unidentified" = "[Uu]nidentified",
  "uncultured" = "[Uu]ncultured",
  "incertae sedis" = "[Ii]ncertae[_\\s]?[Ss]edis",
  "metagenome" = "^[Mm]etagenome$",
  "environmental" = "^[Ee]nvironmental",
  "empty QIIME-style rank" = "^[kpcofgs]__$",
  "unknown species (_sp prefix)" = "^_sp",
  "unknown species (_species prefix)" = "^_species",
  "unknown cluster (_uc prefix, e.g. MMseqs2 assignation)" = "_uc$",
  "unknown ranks (_X, _XX, ... prefix e.g. PR2 database)" = "__X+$"
  )
}
