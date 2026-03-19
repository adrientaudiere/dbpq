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
#' # count_seq_db("my_database.fasta")
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
#' @examples
#' # count_pattern_db("my_database.fasta", "Fungi")
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
#' sequence headers. Requires taxonomy encoded in headers following
#' the convention `k__Kingdom;p__Phylum;...` or similar.
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param rank_prefix (Character, default `"k__"`) The prefix identifying the
#'   taxonomic rank to extract (e.g., `"k__"` for kingdom, `"p__"` for phylum,
#'   `"c__"` for class, `"o__"` for order, `"f__"` for family, `"g__"` for
#'   genus, `"s__"` for species).
#'
#' @returns A named integer vector of counts, sorted in decreasing order.
#'   Names are the taxonomic rank values.
#' @export
#' @author Adrien Taudière
#' @examples
#' # list_ranks_db("my_database.fasta", rank_prefix = "p__")
list_ranks_db <- function(file, rank_prefix = "k__") {
  lines <- read_lines_db(file)
  headers <- lines[grepl("^>", lines)]

  pattern <- paste0(rank_prefix, "[^;,\\s]+")
  matches <- stringr::str_extract(headers, pattern)
  matches <- matches[!is.na(matches)]

  counts <- sort(table(matches), decreasing = TRUE)
  result <- as.integer(counts)
  names(result) <- names(counts)
  return(result)
}


#' Summarize a FASTA reference database
#'
#' @description
#' Provides an overview of a FASTA reference database: number of sequences,
#' sequence length distribution, and taxonomic coverage at each rank.
#'
#' @param file (Character, required) Path to a FASTA file (plain or gzip).
#' @param rank_prefixes (Character vector) Taxonomic rank prefixes to
#'   summarize. Defaults to kingdom through species.
#'
#' @returns A list with components:
#'   - `n_sequences`: total number of sequences
#'   - `length_summary`: summary statistics of sequence lengths
#'   - `ranks`: a named list of unique count per rank
#' @export
#' @author Adrien Taudière
#' @examples
#' # summarize_db("my_database.fasta")
summarize_db <- function(
  file,
  rank_prefixes = c(
    "k__", "p__", "c__", "o__", "f__", "g__", "s__"
  )
) {
  dna <- Biostrings::readDNAStringSet(file)
  n_seq <- length(dna)
  len_summary <- summary(Biostrings::width(dna))

  rank_counts <- vapply(
    rank_prefixes,
    \(prefix) {
      pattern <- paste0(prefix, "[^;,\\s]+")
      matches <- stringr::str_extract(names(dna), pattern)
      sum(!is.na(matches))
    },
    integer(1)
  )
  names(rank_counts) <- gsub("__$", "", rank_prefixes)

  result <- list(
    n_sequences = n_seq,
    length_summary = len_summary,
    ranks = rank_counts
  )

  message("Database: ", basename(file))
  message("Sequences: ", n_seq)
  message(
    "Sequence length: ",
    min(Biostrings::width(dna)), "-",
    max(Biostrings::width(dna)),
    " (mean: ", round(mean(Biostrings::width(dna)), 1), ")"
  )
  for (r in names(rank_counts)) {
    message("  ", r, ": ", rank_counts[[r]], " sequences with annotation")
  }

  invisible(result)
}
