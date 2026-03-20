#' Count sequences in a FASTA file
#'
#' @description
#' Counts the number of sequences in a FASTA file by counting header lines
#' (lines starting with `>`). Accepts gzip files.
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#'
#' @returns An integer, the number of sequences.
#' @export
#' @author Adrien Taudière
#' @seealso [count_pattern_db()]
#' @examples
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' count_seq_db(db)
count_seq_db <- function(file) {
  count_pattern_db(file, pattern = ">")
}


#' Count lines matching a pattern in a FASTA file
#'
#' @description
#' Count lines (sequences if fasta file) matching a pattern.
#' Accepts gzip files. May not work on Windows.
#'
#' @param file (Character, required) Path to a file (plain or gzip),
#'   often a FASTA file.
#' @param pattern (Character, default `">"`) A pattern to search for.
#'
#' @returns An integer, the number of matching lines.
#' @export
#' @author Adrien Taudière
#' @seealso [filter_db()], [count_seq_db()]
#' @examplesIf tolower(Sys.info()[["sysname"]]) != "windows"
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' count_pattern_db(db, "Amanita")
count_pattern_db <- function(file, pattern = ">") {
  if (is_gzipped(file)) {
    count <- as.numeric(system(
      paste0("zcat ", normalizePath(file), " | grep -c '", pattern, "' "),
      intern = TRUE
    ))
  } else {
    count <- as.numeric(system(
      paste0("cat ", normalizePath(file), " | grep -c '", pattern, "' "),
      intern = TRUE
    ))
  }
  return(count)
}


#' List and count taxonomic ranks from a FASTA database
#'
#' @description
#' Extracts and counts occurrences of a given taxonomic rank from FASTA
#' sequence headers. Supports both prefix-based formats (unite, sintax,
#' greengenes2) and positional formats (dada2, pr2).
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param rank_prefix (Character, default `"k__"`) The prefix identifying the
#'   taxonomic rank to extract (e.g., `"k__"` for kingdom, `"p__"` for phylum).
#'   Ignored if `tax_format` is provided.
#' @param tax_format (Character) If provided, one of `"unite"`, `"sintax"`,
#'   `"greengenes2"`, or `"pr2"`. Overrides `rank_prefix` with
#'   the first rank from [tax_prefixes()]. If `NULL` (default), `rank_prefix`
#'   is used as-is.
#' @param rank_position (Integer) For positional (prefix-less) taxonomy
#'   headers, the 1-based position of the rank to extract from the
#'   semicolon-delimited string. Can be used with `tax_format = "pr2"` or
#'   standalone (without `tax_format`). Ignored for prefix-based formats.
#'
#' @returns A named integer vector of counts, sorted in decreasing order.
#'   Names are the taxonomic rank values.
#' @export
#' @author Adrien Taudière
#' @seealso [tax_prefixes()], [detect_tax_format()], [summarize_db()]
#' @examples
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' list_ranks_db(db, rank_prefix = "p__")
#' list_ranks_db(db, tax_format = "unite")
list_ranks_db <- function(
  file,
  rank_prefix = "k__",
  tax_format = NULL,
  rank_position = NULL
) {
  lines <- read_lines_db(file)
  headers <- lines[grepl("^>", lines)]

  # Positional extraction: rank_position can be used with or without

  # tax_format, for any semicolon-delimited positional taxonomy
  if (!is.null(tax_format)) {
    rank_info <- tax_prefixes(tax_format)

    if (is.integer(rank_info)) {
      # Positional format (pr2)
      pos <- if (!is.null(rank_position)) rank_position else rank_info[[1]]
      matches <- extract_rank_by_position(headers, position = pos)
      matches <- matches[!is.na(matches)]

      counts <- sort(table(matches), decreasing = TRUE)
      result <- as.integer(counts)
      names(result) <- names(counts)
      return(result)
    }

    # Prefix-based format
    rank_prefix <- rank_info[[1]]
  } else if (!is.null(rank_position)) {
    # Direct positional extraction without tax_format
    matches <- extract_rank_by_position(headers, position = rank_position)
    matches <- matches[!is.na(matches)]

    counts <- sort(table(matches), decreasing = TRUE)
    result <- as.integer(counts)
    names(result) <- names(counts)
    return(result)
  }

  pattern <- paste0(rank_prefix, "[^;,\\s]+")
  matches <- stringr::str_extract(headers, pattern)
  matches <- matches[!is.na(matches)]

  counts <- sort(table(matches), decreasing = TRUE)
  result <- as.integer(counts)
  names(result) <- names(counts)
  result
}


#' Summarize a FASTA reference database
#'
#' @description
#' Provides an overview of a FASTA reference database: number of sequences,
#' sequence length distribution, and taxonomic coverage at each rank.
#' Supports both prefix-based formats (unite, sintax, greengenes2) and
#' positional formats (dada2, pr2).
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param rank_prefixes (Character vector) Taxonomic rank prefixes to
#'   summarize. Defaults to kingdom through species. Ignored if `tax_format`
#'   is provided.
#' @param tax_format (Character) If provided, one of `"unite"`, `"sintax"`,
#'   `"greengenes2"`, or `"pr2"`. Overrides `rank_prefixes`
#'   with the full set from [tax_prefixes()]. If `"auto"`, the format is
#'   detected from the file headers using [detect_tax_format()]. If `NULL`
#'   (default), `rank_prefixes` is used as-is.
#'
#' @returns A list with components:
#'   - `n_sequences`: total number of sequences
#'   - `length_summary`: summary statistics of sequence lengths
#'   - `ranks`: a named integer vector of annotated counts per rank
#' @export
#' @author Adrien Taudière
#' @seealso [tax_prefixes()], [detect_tax_format()], [list_ranks_db()]
#' @examples
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' summarize_db(db)
#' summarize_db(db, tax_format = "unite")
summarize_db <- function(
  file,
  rank_prefixes = c(
    "k__",
    "p__",
    "c__",
    "o__",
    "f__",
    "g__",
    "s__"
  ),
  tax_format = NULL
) {
  if (!is.null(tax_format)) {
    if (tax_format == "auto") {
      tax_format <- detect_tax_format(file)
      if (tax_format == "unknown") {
        message(
          "Could not auto-detect taxonomy format. ",
          "Using unite prefixes (k__, p__, ...)."
        )
        tax_format <- "unite"
      } else {
        message("Detected taxonomy format: ", tax_format)
      }
    }
    rank_prefixes <- tax_prefixes(tax_format)
  }

  dna <- Biostrings::readDNAStringSet(file)
  n_seq <- length(dna)
  len_summary <- summary(Biostrings::width(dna))

  if (is.integer(rank_prefixes)) {
    # Positional format (dada2, pr2)
    headers <- paste0(">", names(dna))
    rank_counts <- vapply(
      rank_prefixes,
      \(pos) {
        matches <- extract_rank_by_position(headers, position = pos)
        sum(!is.na(matches) & nzchar(matches))
      },
      integer(1)
    )
    names(rank_counts) <- names(rank_prefixes)
  } else {
    # Prefix-based format (unite, sintax, greengenes2)
    rank_counts <- vapply(
      rank_prefixes,
      \(prefix) {
        pattern <- paste0(prefix, "[^;,\\s]+")
        matches <- stringr::str_extract(names(dna), pattern)
        sum(!is.na(matches))
      },
      integer(1)
    )
    if (!is.null(names(rank_prefixes))) {
      names(rank_counts) <- names(rank_prefixes)
    } else {
      names(rank_counts) <- gsub("[_:]+$", "", rank_prefixes)
    }
  }

  result <- list(
    n_sequences = n_seq,
    length_summary = len_summary,
    ranks = rank_counts
  )

  message("Database: ", basename(file))
  message("Sequences: ", n_seq)
  message(
    "Sequence length: ",
    min(Biostrings::width(dna)),
    "-",
    max(Biostrings::width(dna)),
    " (mean: ",
    round(mean(Biostrings::width(dna)), 1),
    ")"
  )
  for (r in names(rank_counts)) {
    message("  ", r, ": ", rank_counts[[r]], " sequences with annotation")
  }

  invisible(result)
}
