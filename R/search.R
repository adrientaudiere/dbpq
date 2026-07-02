#' Search sequences by taxonomic name in a FASTA database
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
#' Searches a FASTA database (plain or gzip) for sequences whose header
#' matches a set of taxonomic name parts. This is useful to retrieve all
#' sequences assigned to a given taxon across databases that use different
#' header formats (e.g. UNITE `g__Apiotrichum;s__akiyoshidainum` vs SINTAX
#' `k:Fungi,...,g:Apiotrichum,s:akiyoshidainum`).
#'
#' Matching is case-insensitive by default and based on substrings, so the
#' rank prefixes and separators used by a given format do not matter. Provide
#' multiple name parts in `taxa` to narrow the search: by default a header
#' matches only when **all** parts are present (`match = "all"`); use
#' `match = "any"` to match when at least one part is present.
#'
#' On Linux/macOS, filtering is done with `awk` in a single streaming pass
#' over the file, so memory usage stays low even for multi-GB reference
#' databases — only the matched records are loaded into R. On Windows (or
#' whenever `awk` is unavailable), the function automatically falls back to
#' an in-memory [Biostrings::readDNAStringSet()] filter, which is slower and
#' more memory-hungry for large databases but produces the same result.
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param taxa (Character, required) One or more taxonomic name parts to
#'   search for in sequence headers, e.g. `c("Apiotrichum", "akiyoshidainum")`.
#' @param match (Character, default `"all"`) Whether a header must contain
#'   all (`"all"`) or at least one (`"any"`) of the `taxa` parts.
#' @param case_sensitive (Logical, default `FALSE`) If `TRUE`, matching is
#'   case-sensitive.
#' @param output_path (Character, default `NULL`) Optional path to write the
#'   matched sequences to a FASTA file. A `.gz` extension produces a gzipped
#'   file. When set, the [Biostrings::DNAStringSet-class] is returned
#'   invisibly.
#'
#' @returns A [Biostrings::DNAStringSet-class] of the matching sequences,
#'   with original headers preserved (including all taxonomy information).
#'   An empty `DNAStringSet` (length 0) is returned when nothing matches.
#' @export
#' @author Adrien Taudière
#' @seealso [filter_db()] for a shell-based header filter that writes to a
#'   file; [format_fasta_db()] to reformat the retrieved sequences.
#' @examples
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#'
#' # Retrieve all Amanita sequences (single name part)
#' search_taxa_db(db, "Amanita")
#'
#' # Narrow to a species with two name parts (AND logic)
#' search_taxa_db(db, c("Amanita", "muscaria"))
#'
#' # Match any of several genera (OR logic)
#' search_taxa_db(db, c("Amanita", "Fusarium"), match = "any")
#'
#' # Write the result to a gzipped FASTA file and read it back
#' out <- tempfile(fileext = ".fasta.gz")
#' search_taxa_db(db, "Boletus", output_path = out)
#' Biostrings::readDNAStringSet(out)
search_taxa_db <- function(
  file,
  taxa,
  match = c("all", "any"),
  case_sensitive = FALSE,
  output_path = NULL
) {
  match <- match.arg(match)

  if (is.null(taxa) || !is.character(taxa) || length(taxa) == 0L) {
    stop("`taxa` must be a non-empty character vector of taxonomic name parts.")
  }
  if (!file.exists(file)) {
    stop("`file` does not exist: ", file)
  }

  gz <- is_gzipped(file)
  reader <- if (gz) "zcat" else "cat"

  # Pass taxa to awk via the environment (ENVIRON[]) so that arbitrary taxon
  # names — including names with quotes, backslashes, or shell metacharacters
  # — are transmitted verbatim and never need shell quoting. index() does a
  # literal substring search (no regex), so no pattern escaping is needed.
  n <- length(taxa)
  env_names <- paste0("DBPQ_TAXA_", seq_len(n))
  env_vals <- if (case_sensitive) taxa else tolower(taxa)
  names(env_vals) <- env_names
  do.call(Sys.setenv, as.list(env_vals))
  on.exit(Sys.unsetenv(env_names), add = TRUE)

  cond_parts <- vapply(seq_len(n), function(i) {
    if (case_sensitive) {
      sprintf("index($1, ENVIRON[\"%s\"])", env_names[i])
    } else {
      sprintf("index(tolower($1), ENVIRON[\"%s\"])", env_names[i])
    }
  }, character(1))
  op <- if (match == "all") " && " else " || "
  condition <- paste(cond_parts, collapse = op)

  # RS=">" splits the stream into one record per FASTA entry; $1 is the header
  # line (without the leading ">"), $0 is the whole entry. printf ">%s" writes
  # the entry back with its ">" restored, preserving multi-line sequences.
  awk_script <- sprintf(
    "BEGIN{RS=\">\"; FS=\"\\n\"} NR>1 && %s {printf \">%%s\", $0}",
    condition
  )

  tmp <- tempfile(fileext = ".fasta")
  on.exit(unlink(tmp), add = TRUE)

  cmd <- paste(
    reader, shQuote(normalizePath(file)),
    "| awk", shQuote(awk_script),
    ">", shQuote(tmp)
  )
  status <- system(cmd)

  if (status == 0L) {
    if (file.size(tmp) == 0L) {
      res <- Biostrings::DNAStringSet()
    } else {
      res <- Biostrings::readDNAStringSet(tmp)
    }
  } else {
    # awk unavailable or the shell command failed (e.g. stock Windows).
    # Fall back to an in-memory Biostrings filter — slower and more memory-
    # hungry for large DBs, but produces the same DNAStringSet result.
    cli::cli_alert_warning(
      "Streaming filter via `awk` failed (exit status {status}). \\
      Falling back to in-memory filtering, which is slower for large databases."
    )
    unlink(tmp)
    res <- .search_taxa_db_in_memory(file, taxa, match, case_sensitive)
  }

  if (length(res) == 0L) {
    cli::cli_alert_info("No sequences matched the provided taxa.")
  }

  if (!is.null(output_path)) {
    Biostrings::writeXStringSet(
      res,
      filepath = output_path,
      compress = grepl("\\.gz$", output_path, ignore.case = TRUE)
    )
    return(invisible(res))
  }

  res
}

#' In-memory fallback for [search_taxa_db()]
#'
#' Reads the whole FASTA with [Biostrings::readDNAStringSet()] and filters
#' headers in R. Used when the streaming `awk` path is unavailable.
#'
#' @param file (Character) Path to a FASTA file (plain or gzip).
#' @param taxa (Character) Taxonomic name parts to search for.
#' @param match (Character) Either `"all"` or `"any"`.
#' @param case_sensitive (Logical) Whether matching is case-sensitive.
#'
#' @returns A [Biostrings::DNAStringSet-class] of matching sequences.
#' @keywords internal
.search_taxa_db_in_memory <- function(file, taxa, match, case_sensitive) {
  dna <- Biostrings::readDNAStringSet(file)
  headers <- names(dna)

  if (length(headers) == 0L) {
    return(dna)
  }

  patterns <- if (case_sensitive) taxa else tolower(taxa)
  haystack <- if (case_sensitive) headers else tolower(headers)

  detect <- lapply(patterns, function(p) {
    grepl(p, haystack, fixed = TRUE)
  })
  found <- do.call(cbind, detect)

  if (match == "all") {
    keep <- rowSums(found) == length(taxa)
  } else {
    keep <- rowSums(found) >= 1L
  }

  dna[keep]
}
