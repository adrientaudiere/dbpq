#' Count sequences in a FASTA file
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
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
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
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
  reader <- if (is_gzipped(file)) {
    "zcat "
  } else {
    "cat "
  }
  # `grep -c` exits with status 1 (and prints "0") when there are no matches,
  # which makes `system()` emit a spurious warning; suppress it. `shQuote()`
  # protects the path and pattern from shell metacharacters.
  count <- suppressWarnings(as.numeric(system(
    paste0(
      reader,
      shQuote(normalizePath(file)),
      " | grep -c ",
      shQuote(pattern)
    ),
    intern = TRUE
  )))
  return(count)
}


#' Count unwanted values in a taxonomy table
#'
#' @description
#' Scans a taxonomy table for common problematic values such as NA-like
#' strings, placeholder labels (`"unclassified"`, `"unknown"`, etc.),
#' and empty QIIME-style rank prefixes. The input can be a
#' [phyloseq][phyloseq::phyloseq-class] object or a FASTA reference database
#' file.
#'
#' Returns a tibble summarising, for each pattern found, how many matches
#' occur in each taxonomic rank.
#'
#' @param x Either:
#'   - a character string giving the path to a FASTA file (plain or gzip), or
#'   - a [phyloseq][phyloseq::phyloseq-class] object with a taxonomy table.
#' @param patterns (Character vector) Regular expressions to search for.
#'   When MiscMetabar is installed, defaults to
#'   [MiscMetabar::unwanted_tax_patterns]; otherwise falls back to a
#'   built-in copy of the same patterns. See **Details**.
#' @param tax_format (Character) Taxonomy format of the FASTA file. One of
#'   `"unite"`, `"sintax"`, `"greengenes2"`, `"pr2"`, or `"auto"`.
#'   Only used when `x` is a file path. If `"auto"` (default), the format
#'   is detected with [detect_tax_format()]. Ignored when `x` is a phyloseq
#'   object.
#'
#' @details
#' The default patterns are:
#' \describe{
#'   \item{`"^[Nn][Aa][Nn]?$"`}{NaN, nan, NA, na}
#'   \item{`"^[Nn]/[Aa]$"`}{N/A, n/a}
#'   \item{`"^[Nn]one$"`}{None, none}
#'   \item{`"^$"`}{empty string}
#'   \item{`"^\\s+$"`}{whitespace only}
#'   \item{`"[Uu]nclassified"`}{unclassified, Unclassified, xxx_unclassified}
#'   \item{`"[Uu]nknown"`}{unknown, Unknown, xxx_unknown}
#'   \item{`"[Uu]nidentified"`}{unidentified, Unidentified}
#'   \item{`"[Uu]ncultured"`}{uncultured, Uncultured}
#'   \item{`"[Ii]ncertae[_\\s]?[Ss]edis"`}{incertae_sedis, Incertae sedis}
#'   \item{`"^[Mm]etagenome$"`}{metagenome, Metagenome}
#'   \item{`"^[Ee]nvironmental"`}{environmental, Environmental}
#'   \item{`"^[kpcofgs]__$"`}{empty QIIME-style rank prefixes}
#' }
#'
#' @returns A [tibble][tibble::tibble] with columns:
#'   \describe{
#'     \item{`pattern`}{The regular expression that matched.}
#'     \item{`description`}{A human-readable label for the pattern.}
#'     \item{`rank`}{The taxonomic rank (column name) where matches were
#'       found.}
#'     \item{`n_matches`}{Number of values matching the pattern in that
#'       rank.}
#'     \item{`example_values`}{Up to 3 unique matching values
#'       (comma-separated).}
#'   }
#'   Rows with zero matches are omitted.
#' @export
#' @author Adrien Taudière
#' @seealso [summarize_db()], [list_ranks_db()]
#' @examples
#' # From a FASTA file (no unwanted values in example data)
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' count_unwanted_tax(db)
#'
#' if(requireNamespace("MiscMetabar", quietly = TRUE)) {
#'  ref_fasta <- Biostrings::readDNAStringSet(system.file("extdata",
#'    "mini_UNITE_fungi.fasta.gz",
#'    package = "MiscMetabar", mustWork = TRUE
#'  ))
#' data("data_fungi_mini", package = "MiscMetabar")
#' physeq_new <- MiscMetabar::assign_mmseqs2(
#'    MiscMetabar::data_fungi_mini,
#'    ref_fasta = ref_fasta,
#'    behavior = "add_to_phyloseq"
#'  )
#' count_unwanted_tax(physeq_new)
#' }

count_unwanted_tax <- function(
  #' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
  #' <img src="https://img.shields.io/badge/lifecycle-maturing-blue" alt="lifecycle-maturing"></a>
  #'
  #' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
  #' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
  #'
  x,
  patterns = unwanted_tax_patterns_default(),
  tax_format = "auto"
) {
  # Build description lookup from named patterns vector
  pat_values <- unname(patterns)
  pat_descriptions <- if (!is.null(names(patterns))) {
    names(patterns)
  } else {
    pat_values
  }
  names(pat_descriptions) <- pat_values

  tax_mat <- extract_tax_matrix(x, tax_format = tax_format)
  rank_names <- colnames(tax_mat)

  results <- list()
  for (pat in pat_values) {
    for (rank in rank_names) {
      vals <- tax_mat[, rank]
      vals <- vals[!is.na(vals)]
      matched <- vals[grepl(pat, vals)]
      if (length(matched) > 0) {
        unique_matched <- unique(matched)
        examples <- paste(
          utils::head(unique_matched, 3),
          collapse = ", "
        )
        results[[length(results) + 1]] <- tibble::tibble(
          pattern = pat,
          description = pat_descriptions[[pat]],
          rank = rank,
          n_matches = length(matched),
          example_values = examples
        )
      }
    }
  }

  if (length(results) == 0) {
    result <- tibble::tibble(
      pattern = character(0),
      description = character(0),
      rank = character(0),
      n_matches = integer(0),
      example_values = character(0)
    )
    message("No unwanted taxonomic values found.")
    return(result)
  }

  result <- do.call(rbind, results)
  total <- sum(result$n_matches)
  n_patterns <- length(unique(result$pattern))
  message(
    "Found ",
    total,
    " unwanted value(s) matching ",
    n_patterns,
    " pattern(s) across ",
    length(unique(result$rank)),
    " rank(s)."
  )

  if (inherits(x, "phyloseq")) {
    message(
      "Tip: use MiscMetabar::verify_tax_table() ",
      "to clean these values in your phyloseq object."
    )
  }

  result
}


# ——————————————————————————————————————————————————————————————————————
# Internal: extract taxonomy matrix from various inputs
# ——————————————————————————————————————————————————————————————————————

#' Extract a taxonomy matrix from a phyloseq object or FASTA file
#'
#' @param x A file path (character) or a phyloseq object.
#' @param tax_format Taxonomy format (only used for file input).
#'
#' @returns A character matrix with rows = taxa and columns = ranks.
#' @keywords internal
extract_tax_matrix <- function(x, tax_format = "auto") {
  if (inherits(x, "phyloseq")) {
    if (is.null(x@tax_table)) {
      stop(
        "The phyloseq object does not contain a taxonomy table.",
        call. = FALSE
      )
    }
    mat <- as(x@tax_table, "matrix")
    storage.mode(mat) <- "character"
    return(mat)
  }

  if (!is.character(x) || length(x) != 1) {
    stop(
      "`x` must be a file path (character) or a phyloseq object.",
      call. = FALSE
    )
  }

  # Read FASTA headers and parse taxonomy
  lines <- read_lines_db(x)
  headers <- lines[grepl("^>", lines)]

  if (tax_format == "auto") {
    tax_format <- detect_tax_format(x)
  }

  rank_info <- if (tax_format != "unknown") {
    tax_prefixes(tax_format)
  } else {
    # Fall back to UNITE-style prefixes
    tax_prefixes("unite")
  }

  if (is.integer(rank_info)) {
    # Positional format
    mat <- vapply(
      names(rank_info),
      \(rname) {
        extract_rank_by_position(
          headers,
          position = rank_info[[rname]]
        )
      },
      character(length(headers))
    )
    if (length(headers) == 1) {
      mat <- matrix(
        mat,
        nrow = 1,
        dimnames = list(NULL, names(rank_info))
      )
    }
  } else {
    # Prefix-based format
    # Match prefix followed by optional value (captures empty ranks
    # like c__)
    mat <- vapply(
      rank_info,
      \(prefix) {
        esc <- gsub(
          "([.\\\\|(){}^$*+?])",
          "\\\\\\1",
          prefix
        )
        pattern <- paste0(esc, "([^;,\\s]*)")
        stringr::str_extract(headers, pattern) |>
          stringr::str_remove(paste0("^", esc))
      },
      character(length(headers))
    )
    if (length(headers) == 1) {
      mat <- matrix(
        mat,
        nrow = 1,
        dimnames = list(NULL, names(rank_info))
      )
    }
    colnames(mat) <- names(rank_info)
  }

  mat
}


#' List and count taxonomic ranks from a FASTA database
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
#' Extracts and counts occurrences of a given taxonomic rank from FASTA
#' sequence headers. Supports both prefix-based formats (unite, sintax,
#' greengenes2) and positional formats (dada2, pr2).
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param rank_prefix (Character, default `"k__"`) The prefix identifying
#'   the taxonomic rank to extract (e.g., `"k__"` for kingdom, `"p__"` for
#'   phylum). Ignored if `tax_format` is provided.
#' @param tax_format (Character) If provided, one of `"unite"`, `"sintax"`,
#'   `"greengenes2"`, or `"pr2"`. Overrides `rank_prefix` with
#'   the first rank from [tax_prefixes()]. If `NULL` (default),
#'   `rank_prefix` is used as-is.
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
      pos <- if (!is.null(rank_position)) {
        rank_position
      } else {
        rank_info[[1]]
      }
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
    matches <- extract_rank_by_position(
      headers,
      position = rank_position
    )
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

  if (length(result) == 0 && length(headers) > 0) {
    message(
      "No taxa matched prefix '",
      rank_prefix,
      "'. The file may use a different taxonomy format; check with ",
      "detect_tax_format() and pass `tax_format` or a matching `rank_prefix`."
    )
  }

  result
}


#' Summarize a FASTA reference database
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
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

  if (n_seq == 0) {
    # Empty database: avoid min()/max() warnings on a zero-length width vector
    rank_names <- if (!is.null(names(rank_prefixes))) {
      names(rank_prefixes)
    } else {
      gsub("[_:]+$", "", rank_prefixes)
    }
    rank_counts <- stats::setNames(
      integer(length(rank_prefixes)),
      rank_names
    )
    message("Database: ", basename(file))
    message("Sequences: 0 (empty database; no length statistics)")
    return(invisible(list(
      n_sequences = 0L,
      length_summary = summary(numeric(0)),
      ranks = rank_counts
    )))
  }

  len_summary <- summary(Biostrings::width(dna))

  if (is.integer(rank_prefixes)) {
    # Positional format (dada2, pr2)
    headers <- paste0(">", names(dna))
    rank_counts <- vapply(
      rank_prefixes,
      \(pos) {
        matches <- extract_rank_by_position(
          headers,
          position = pos
        )
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
    message(
      "  ",
      r,
      ": ",
      rank_counts[[r]],
      " sequences with annotation"
    )
  }

  invisible(result)
}
