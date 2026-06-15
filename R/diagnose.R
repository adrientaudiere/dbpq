# ——————————————————————————————————————————————————————————————————————
# Diagnose reference databases: format, integrity, and quality checks
# ——————————————————————————————————————————————————————————————————————

#' Diagnose one or several FASTA reference databases
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
#' Runs format, integrity, and quality checks on one or more FASTA reference
#' databases and returns a structured diagnosis: per-file statistics,
#' per-rank taxonomic coverage, a table of collected warnings, a cross-file
#' comparison (which flags problems such as a **mixed taxonomy format** across
#' files), and (optionally) diagnostic plots.
#'
#' The three axes checked are:
#' \describe{
#'   \item{Format}{Is the file valid FASTA? Which taxonomy format is detected
#'     ([detect_tax_format()])? Are the taxonomy prefixes consistent across
#'     all headers?}
#'   \item{Integrity}{Can the file be read to completion (a truncated gzip
#'     fails here)? Are there empty sequences or duplicated sequence IDs?}
#'   \item{Quality}{Sequence-length distribution and unusually short
#'     sequences, percentage of sequences annotated at each rank, ambiguous
#'     (non-ACGT) bases, duplicated sequences, and unwanted taxonomic values
#'     ([count_unwanted_tax()]).}
#' }
#'
#' @param files (Character vector, required) One or more paths to FASTA files
#'   (plain or gzip).
#' @param tax_format (Character, default `"auto"`) Taxonomy format to assume
#'   for every file. One of `"auto"`, `"unite"`, `"sintax"`,
#'   `"greengenes2"`, `"pr2"`, or `"dada2"`. When `"auto"` (default) the
#'   format is detected per file from its headers.
#' @param plot (Logical, default `TRUE`) Whether to build diagnostic plots.
#'   Requires the \pkg{ggplot2} package; when it is not installed, `$plots`
#'   is `NULL` and a message is emitted.
#' @param min_length (Integer, default `200`) Sequences shorter than this are
#'   counted as "short" and raise a quality warning.
#' @param check_duplicates (Logical, default `TRUE`) Whether to look for
#'   duplicated sequences. This compares full sequences and can be slow on
#'   very large databases; set to `FALSE` to skip.
#' @param verbose (Logical, default `TRUE`) Whether to show a \pkg{cli}
#'   progress bar (with an ETA) while files are processed, then print a
#'   summary and the collected warnings.
#'
#' @returns An object of class `"dbpq_diagnosis"`: a list with components
#'   \describe{
#'     \item{`stats`}{A [tibble][tibble::tibble], one row per file, with
#'       sequence counts, length statistics, and problem counts.}
#'     \item{`coverage`}{A long tibble of per-rank annotation coverage
#'       (`file`, `rank`, `n_annotated`, `pct_annotated`).}
#'     \item{`warnings`}{A tibble of collected issues (`file`, `check`,
#'       `severity`, `message`); `severity` is one of `"info"`, `"warning"`,
#'       `"error"`. Cross-file issues have `file = NA`.}
#'     \item{`cross_file`}{A list describing agreement across files
#'       (`formats`, `format_agreement`, `n_files`).}
#'     \item{`plots`}{A list of \pkg{ggplot2} objects (`length`, `coverage`),
#'       or `NULL`.}
#'   }
#' @export
#' @author Adrien Taudière
#' @seealso [summarize_db()], [detect_tax_format()], [count_unwanted_tax()]
#' @examples
#' unite <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' diag <- diagnose_db(unite)
#' diag$stats
#'
#' # Several files at once: a mismatched taxonomy format is flagged
#' sintax <- system.file("extdata", "example_sintax.fasta", package = "dbpq")
#' diag2 <- diagnose_db(c(unite, sintax))
#' diag2$warnings
diagnose_db <- function(
  files,
  tax_format = "auto",
  plot = TRUE,
  min_length = 200L,
  check_duplicates = TRUE,
  verbose = TRUE
) {
  if (!is.character(files) || length(files) == 0) {
    stop(
      "`files` must be a non-empty character vector of paths.",
      call. = FALSE
    )
  }
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) {
    stop(
      "File(s) not found: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  stats_rows <- list()
  coverage_rows <- list()
  warn_rows <- list()
  detected_formats <- character(length(files))

  if (verbose) {
    cli::cli_progress_bar(
      format = paste0(
        "{cli::pb_spin} Diagnosing databases {cli::pb_current}/",
        "{cli::pb_total} | {cli::pb_bar} {cli::pb_percent} | ",
        "ETA: {cli::pb_eta} | {cli::pb_status}"
      ),
      total = length(files),
      clear = FALSE
    )
  }

  for (i in seq_along(files)) {
    file <- files[[i]]
    if (verbose) {
      cli::cli_progress_update(set = i - 1L, status = basename(file))
    }
    res <- diagnose_one_db(
      file,
      tax_format = tax_format,
      min_length = min_length,
      check_duplicates = check_duplicates
    )
    stats_rows[[i]] <- res$stats
    coverage_rows[[i]] <- res$coverage
    warn_rows[[i]] <- res$warnings
    detected_formats[[i]] <- res$stats$format
  }
  if (verbose) {
    cli::cli_progress_update(set = length(files), status = "done")
    cli::cli_progress_done()
  }

  stats <- dplyr::bind_rows(stats_rows)
  coverage <- dplyr::bind_rows(coverage_rows)

  # ---- Cross-file checks --------------------------------------------------
  names(detected_formats) <- basename(files)
  comparable_formats <- setdiff(unique(detected_formats), c("unknown"))
  format_agreement <- length(comparable_formats) <= 1
  cross_file <- list(
    formats = detected_formats,
    format_agreement = format_agreement,
    n_files = length(files)
  )

  if (length(files) > 1 && !format_agreement) {
    warn_rows[[length(warn_rows) + 1]] <- diagnosis_warning(
      file = NA_character_,
      check = "format",
      severity = "warning",
      message = paste0(
        "Mixed taxonomy formats across files: ",
        paste(
          unique(detected_formats),
          collapse = ", "
        ),
        ". Databases may not be directly comparable or mergeable."
      )
    )
  }

  warnings <- dplyr::bind_rows(warn_rows)

  # ---- Plots --------------------------------------------------------------
  plots <- NULL
  if (plot) {
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      plots <- diagnosis_plots(stats, coverage)
    } else {
      cli::cli_alert_info(
        "Package {.pkg ggplot2} is not installed; skipping plots."
      )
    }
  }

  result <- structure(
    list(
      stats = stats,
      coverage = coverage,
      warnings = warnings,
      cross_file = cross_file,
      plots = plots
    ),
    class = "dbpq_diagnosis"
  )

  if (verbose) {
    diagnosis_report(result)
  }

  invisible(result)
}


# ——————————————————————————————————————————————————————————————————————
# Internal: diagnose a single file
# ——————————————————————————————————————————————————————————————————————

#' Diagnose a single FASTA database
#'
#' @param file Path to a FASTA file.
#' @param tax_format Taxonomy format or `"auto"`.
#' @param min_length Minimum acceptable sequence length.
#' @param check_duplicates Whether to detect duplicated sequences.
#'
#' @returns A list with `stats` (one-row tibble), `coverage` (tibble),
#'   and `warnings` (tibble).
#' @keywords internal
diagnose_one_db <- function(
  file,
  tax_format = "auto",
  min_length = 200L,
  check_duplicates = TRUE
) {
  fname <- basename(file)
  warns <- list()

  # ---- Read once (integrity: a truncated/corrupt file fails here) --------
  dna <- tryCatch(
    Biostrings::readDNAStringSet(file),
    error = function(e) {
      e
    }
  )

  if (inherits(dna, "error")) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "integrity",
      "error",
      paste0("File could not be read as FASTA (", conditionMessage(dna), ").")
    )
    stats <- tibble::tibble(
      file = fname,
      path = file,
      format = "unknown",
      valid = FALSE,
      n_sequences = NA_integer_,
      length_min = NA_integer_,
      length_median = NA_real_,
      length_mean = NA_real_,
      length_max = NA_integer_,
      n_short = NA_integer_,
      n_empty_seq = NA_integer_,
      n_dup_id = NA_integer_,
      n_dup_seq = NA_integer_,
      n_ambiguous_seq = NA_integer_,
      pct_ambiguous_bases = NA_real_,
      n_unwanted_tax = NA_integer_,
      n_warnings = length(warns)
    )
    return(list(
      stats = stats,
      coverage = empty_coverage(fname),
      warnings = dplyr::bind_rows(warns)
    ))
  }

  headers <- names(dna)
  n_seq <- length(dna)
  widths <- Biostrings::width(dna)

  # ---- Format -------------------------------------------------------------
  fmt <- if (tax_format == "auto") {
    detect_tax_format_from_headers(headers)
  } else {
    tax_format
  }

  if (n_seq == 0) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "integrity",
      "error",
      "Database is empty (0 sequences)."
    )
  }
  if (fmt == "unknown" && n_seq > 0) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "format",
      "warning",
      "Could not detect a known taxonomy format from the headers."
    )
  }

  # Prefix consistency: every header should carry the format's first rank
  if (n_seq > 0) {
    consistency <- format_consistency(headers, fmt)
    if (!is.na(consistency) && consistency < 1) {
      warns[[length(warns) + 1]] <- diagnosis_warning(
        fname,
        "format",
        "warning",
        paste0(
          round(100 * (1 - consistency), 1),
          "% of headers do not match the expected '",
          fmt,
          "' taxonomy layout (possible mixed/malformed headers)."
        )
      )
    }
  }

  # ---- Integrity ----------------------------------------------------------
  n_empty <- sum(widths == 0)
  if (n_empty > 0) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "integrity",
      "warning",
      paste0(n_empty, " empty sequence(s) (zero length).")
    )
  }

  ids <- sub("\\s.*$", "", headers)
  n_dup_id <- sum(duplicated(ids))
  if (n_dup_id > 0) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "integrity",
      "warning",
      paste0(n_dup_id, " duplicated sequence ID(s).")
    )
  }

  n_dup_seq <- NA_integer_
  if (check_duplicates && n_seq > 0) {
    n_dup_seq <- sum(duplicated(as.character(dna)))
    if (n_dup_seq > 0) {
      warns[[length(warns) + 1]] <- diagnosis_warning(
        fname,
        "quality",
        "info",
        paste0(n_dup_seq, " duplicated sequence(s) (identical bases).")
      )
    }
  }

  # ---- Quality ------------------------------------------------------------
  n_short <- if (n_seq > 0) {
    sum(widths < min_length)
  } else {
    0L
  }
  if (n_short > 0) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "quality",
      "warning",
      paste0(
        n_short,
        " sequence(s) shorter than ",
        min_length,
        " bp."
      )
    )
  }

  n_ambiguous_seq <- 0L
  pct_ambiguous <- 0
  if (n_seq > 0) {
    af <- Biostrings::alphabetFrequency(dna, baseOnly = TRUE)
    other <- af[, "other"]
    n_ambiguous_seq <- sum(other > 0)
    total_bases <- sum(widths)
    pct_ambiguous <- if (total_bases > 0) {
      100 * sum(other) / total_bases
    } else {
      0
    }
    if (n_ambiguous_seq > 0) {
      warns[[length(warns) + 1]] <- diagnosis_warning(
        fname,
        "quality",
        "info",
        paste0(
          n_ambiguous_seq,
          " sequence(s) contain ambiguous (non-ACGT) bases (",
          round(pct_ambiguous, 3),
          "% of all bases)."
        )
      )
    }
  }

  # Unwanted taxonomic values, reusing the package patterns on the headers
  n_unwanted <- count_unwanted_in_headers(headers)
  if (n_unwanted > 0) {
    warns[[length(warns) + 1]] <- diagnosis_warning(
      fname,
      "quality",
      "warning",
      paste0(
        n_unwanted,
        " unwanted taxonomic value(s) in headers ",
        "(e.g. unclassified, unknown, NA-like). ",
        "See count_unwanted_tax() for details."
      )
    )
  }

  # ---- Per-rank coverage --------------------------------------------------
  coverage <- rank_coverage(headers, fmt, fname)

  stats <- tibble::tibble(
    file = fname,
    path = file,
    format = fmt,
    valid = TRUE,
    n_sequences = n_seq,
    length_min = if (n_seq > 0) min(widths) else NA_integer_,
    length_median = if (n_seq > 0) stats::median(widths) else NA_real_,
    length_mean = if (n_seq > 0) mean(widths) else NA_real_,
    length_max = if (n_seq > 0) max(widths) else NA_integer_,
    n_short = as.integer(n_short),
    n_empty_seq = as.integer(n_empty),
    n_dup_id = as.integer(n_dup_id),
    n_dup_seq = n_dup_seq,
    n_ambiguous_seq = as.integer(n_ambiguous_seq),
    pct_ambiguous_bases = pct_ambiguous,
    n_unwanted_tax = as.integer(n_unwanted),
    n_warnings = length(warns)
  )

  list(
    stats = stats,
    coverage = coverage,
    warnings = dplyr::bind_rows(warns)
  )
}


# ——————————————————————————————————————————————————————————————————————
# Internal helpers
# ——————————————————————————————————————————————————————————————————————

#' Build a one-row warning tibble
#' @keywords internal
diagnosis_warning <- function(file, check, severity, message) {
  tibble::tibble(
    file = file,
    check = check,
    severity = severity,
    message = message
  )
}


#' An empty per-file coverage tibble
#' @keywords internal
empty_coverage <- function(fname) {
  tibble::tibble(
    file = character(0),
    rank = character(0),
    n_annotated = integer(0),
    pct_annotated = numeric(0)
  )
}


#' Resolve rank information (prefixes or positions) for a format
#'
#' Returns `NULL` when no rank layout can be derived.
#' @keywords internal
rank_info_for_format <- function(fmt, headers) {
  if (fmt %in% c("unite", "sintax", "greengenes2", "pr2")) {
    return(tax_prefixes(fmt))
  }
  # Positional / unknown: derive level count from the headers themselves
  tax_parts <- vapply(
    sub("^>", "", headers),
    \(h) {
      parts <- strsplit(h, "\\s+")[[1]]
      hit <- parts[grepl(";", parts, fixed = TRUE)]
      if (length(hit) > 0) {
        hit[[1]]
      } else {
        h
      }
    },
    character(1),
    USE.NAMES = FALSE
  )
  n_levels <- vapply(
    tax_parts,
    \(p) {
      length(strsplit(p, ";", fixed = TRUE)[[1]])
    },
    integer(1)
  )
  n_levels <- n_levels[n_levels > 1]
  if (length(n_levels) == 0) {
    return(NULL)
  }
  k <- stats::median(n_levels)
  info <- seq_len(k)
  names(info) <- paste0("level_", seq_len(k))
  info
}


#' Per-rank annotation coverage for one file
#' @keywords internal
rank_coverage <- function(headers, fmt, fname) {
  if (length(headers) == 0) {
    return(empty_coverage(fname))
  }
  rank_info <- rank_info_for_format(fmt, headers)
  if (is.null(rank_info)) {
    return(empty_coverage(fname))
  }

  n <- length(headers)
  if (is.integer(rank_info)) {
    counts <- vapply(
      rank_info,
      \(pos) {
        m <- extract_rank_by_position(headers, position = pos)
        sum(!is.na(m) & nzchar(m))
      },
      integer(1)
    )
  } else {
    counts <- vapply(
      rank_info,
      \(prefix) {
        pattern <- paste0(prefix, "[^;,\\s]+")
        sum(!is.na(stringr::str_extract(headers, pattern)))
      },
      integer(1)
    )
  }

  tibble::tibble(
    file = fname,
    rank = names(rank_info),
    n_annotated = as.integer(counts),
    pct_annotated = 100 * counts / n
  )
}


#' Fraction of headers consistent with the expected format layout
#'
#' Returns `NA` when consistency cannot be assessed for the format.
#' @keywords internal
format_consistency <- function(headers, fmt) {
  n <- length(headers)
  if (n == 0) {
    return(NA_real_)
  }
  if (fmt %in% c("unite", "greengenes2")) {
    prefix <- tax_prefixes(fmt)[[1]]
    return(mean(grepl(prefix, headers, fixed = TRUE)))
  }
  if (fmt == "sintax") {
    return(mean(grepl("tax=", headers, fixed = TRUE)))
  }
  if (fmt %in% c("pr2", "dada2")) {
    return(mean(grepl(";", headers, fixed = TRUE)))
  }
  NA_real_
}


#' Count unwanted taxonomic values within FASTA headers
#' @keywords internal
count_unwanted_in_headers <- function(headers) {
  if (length(headers) == 0) {
    return(0L)
  }
  patterns <- unname(unwanted_tax_patterns_default())
  # Split each header into candidate taxonomic tokens. Note: `\\s` inside a
  # bracket expression is read as a literal "s" by R's default regex engine,
  # so use the POSIX `[:space:]` class for whitespace.
  tokens <- unlist(strsplit(headers, "[[:space:];,|]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  # Strip rank prefixes (k__, d:, etc.) to expose the value
  values <- sub("^[a-zA-Z]__", "", tokens)
  values <- sub("^[a-zA-Z]:", "", values)
  total <- 0L
  for (pat in patterns) {
    total <- total + sum(grepl(pat, values))
  }
  total
}


#' Build diagnostic ggplots
#' @keywords internal
diagnosis_plots <- function(stats, coverage) {
  length_plot <- NULL
  coverage_plot <- NULL

  valid <- stats[
    stats$valid & !is.na(stats$n_sequences) & stats$n_sequences > 0,
  ]

  if (nrow(valid) > 0) {
    length_plot <- ggplot2::ggplot(
      valid,
      ggplot2::aes(
        x = .data$file,
        y = .data$length_mean,
        fill = .data$file
      )
    ) +
      ggplot2::geom_col() +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$length_min, ymax = .data$length_max),
        width = 0.3
      ) +
      ggplot2::labs(
        title = "Sequence length per database",
        subtitle = "Bar = mean; whiskers = min/max",
        x = NULL,
        y = "Length (bp)"
      ) +
      ggplot2::theme(legend.position = "none")
  }

  if (nrow(coverage) > 0) {
    coverage$rank <- factor(coverage$rank, levels = unique(coverage$rank))
    coverage_plot <- ggplot2::ggplot(
      coverage,
      ggplot2::aes(
        x = .data$rank,
        y = .data$pct_annotated,
        fill = .data$file
      )
    ) +
      ggplot2::geom_col(position = ggplot2::position_dodge()) +
      ggplot2::ylim(0, 100) +
      ggplot2::labs(
        title = "Taxonomic annotation coverage",
        x = "Rank",
        y = "% sequences annotated",
        fill = "Database"
      )
  }

  list(length = length_plot, coverage = coverage_plot)
}


#' Print a concise diagnosis report with cli
#' @keywords internal
diagnosis_report <- function(x) {
  stats <- x$stats
  cli::cli_h2("Diagnosed {nrow(stats)} database file{?s}")
  for (i in seq_len(nrow(stats))) {
    s <- stats[i, ]
    if (!isTRUE(s$valid)) {
      cli::cli_alert_danger("{.file {s$file}}: unreadable")
      next
    }
    cli::cli_alert_info(
      paste0(
        "{.file {s$file}} [{s$format}]: {s$n_sequences} seq{?s}, ",
        "length {s$length_min}-{s$length_max} bp"
      )
    )
  }

  if (!x$cross_file$format_agreement) {
    cli::cli_alert_warning("Mixed taxonomy formats across files.")
  }

  w <- x$warnings
  if (nrow(w) == 0) {
    cli::cli_alert_success("No issues detected.")
    return(invisible(NULL))
  }

  n_err <- sum(w$severity == "error")
  n_warn <- sum(w$severity == "warning")
  n_info <- sum(w$severity == "info")
  cli::cli_h3(
    "Issues: {n_err} error{?s}, {n_warn} warning{?s}, {n_info} info"
  )
  for (i in seq_len(nrow(w))) {
    wi <- w[i, ]
    loc <- if (is.na(wi$file)) {
      "<cross-file>"
    } else {
      wi$file
    }
    msg <- "{.file {loc}} ({wi$check}): {wi$message}"
    switch(
      wi$severity,
      error = cli::cli_alert_danger(msg),
      warning = cli::cli_alert_warning(msg),
      cli::cli_alert_info(msg)
    )
  }
  invisible(NULL)
}
