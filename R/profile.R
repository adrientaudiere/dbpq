# ——————————————————————————————————————————————————————————————————————
# Profile reference databases: taxonomic richness and cross-database overlap
# ——————————————————————————————————————————————————————————————————————

# Canonical rank order used to order the x-axis of richness plots and the
# iteration/comparison order of per-rank Venn/UpSet panels.
canonical_rank_levels <- c("k", "d", "p", "c", "o", "f", "g", "s")


# Reorder a character vector of rank names to the canonical order. Ranks not in
# the canonical set (e.g. `level_1`, `level_2`, ... from positional formats) are
# appended in their original order at the end.
order_ranks <- function(ranks) {
  if (length(ranks) == 0) {
    return(ranks)
  }
  in_canon <- match(ranks, canonical_rank_levels)
  canon_first <- ranks[!is.na(in_canon)]
  extras <- ranks[is.na(in_canon)]
  c(
    canon_first[order(in_canon[!is.na(in_canon)])],
    extras
  )
}

#' Profile the taxonomic content of one or several FASTA databases
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
#' Builds a taxonomic profile of one or more FASTA reference databases. It
#' first runs [diagnose_db()] (format/integrity/quality checks) and then adds:
#'
#' - a **richness** table and bar plot giving the number of distinct taxa
#'   (levels) annotated at each taxonomic rank, and
#' - when several databases are supplied, a **cross-database comparison** of
#'   the taxa present at each rank, drawn as a Venn diagram
#'   (\pkg{ggVennDiagram}, up to `venn_max` databases) or an UpSet plot
#'   (\pkg{ComplexUpset}), with one plot per rank.
#'
#' By default the comparison overlaps the *sets of distinct taxon names* at
#' each rank (presence/absence). With `weight_by_seqs = TRUE` the UpSet bars
#' instead show the total number of sequences backing the taxa in each
#' intersection (summed across the databases that contain each taxon).
#'
#' @param files (Character vector, required) One or more paths to FASTA files
#'   (plain or gzip).
#' @param tax_format (Character, default `"auto"`) Taxonomy format, passed to
#'   [diagnose_db()] and used for taxon extraction. One of `"auto"`, `"unite"`,
#'   `"sintax"`, `"greengenes2"`, `"pr2"`, or `"dada2"`.
#' @param weight_by_seqs (Logical, default `FALSE`) When `TRUE`, the
#'   cross-database UpSet plot weights each intersection by the number of
#'   sequences (summed over the databases containing each taxon) rather than
#'   by the number of taxa. Forces an UpSet plot (Venn diagrams cannot be
#'   weighted) and therefore needs \pkg{ComplexUpset}; with ggplot2 >= 4.0.0
#'   this requires the dev version (>= 1.3.6, install with
#'   `remotes::install_github("krassowski/complex-upset")`). When it is
#'   unavailable, an unweighted Venn is drawn instead and the weighted counts
#'   are still returned in `comparison$signatures`.
#' @param plot (Logical, default `TRUE`) Whether to build plots. Requires
#'   \pkg{ggplot2}; the comparison plots additionally require
#'   \pkg{ggVennDiagram} and/or \pkg{ComplexUpset}.
#' @param venn_max (Integer, default `7`) Maximum number of databases for which
#'   a Venn diagram is drawn; beyond this an UpSet plot is used. (Also forced to
#'   UpSet when `weight_by_seqs = TRUE`.)
#' @param verbose (Logical, default `TRUE`) Whether to show a \pkg{cli}
#'   progress bar while reading files and print a summary report.
#' @param ... Further arguments passed to [diagnose_db()] (e.g. `min_length`,
#'   `check_duplicates`).
#'
#' @returns An object of class `"dbpq_profile"`: a list with components
#'   \describe{
#'     \item{`diagnosis`}{The [diagnose_db()] result (a `dbpq_diagnosis`).}
#'     \item{`taxa`}{A long [tibble][tibble::tibble] (`file`, `rank`, `taxon`,
#'       `n_seqs`) of every taxon found at every rank.}
#'     \item{`richness`}{A tibble (`file`, `rank`, `n_levels`,
#'       `n_seqs_annotated`) of per-rank taxonomic richness.}
#'     \item{`comparison`}{`NULL` for a single file; otherwise a list with
#'       `per_db` and `signatures` tibbles, per-rank `membership` data frames,
#'       and per-rank `plots`.}
#'     \item{`plots`}{A list with `richness` (a ggplot) and `comparison` (a
#'       named list of per-rank Venn/UpSet plots, or `NULL`).}
#'   }
#' @export
#' @author Adrien Taudière
#' @seealso [diagnose_db()], [summarize_db()], [list_ranks_db()]
#' @examples
#' unite <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' prof <- profile_db(unite, verbose = FALSE)
#' prof$richness
#'
#' # Compare two databases (needs ggVennDiagram / ComplexUpset for the plots)
#' \donttest{
#' sintax <- system.file("extdata", "example_sintax.fasta", package = "dbpq")
#' prof2 <- profile_db(c(unite, sintax), verbose = FALSE)
#' prof2$comparison$signatures
#' }
profile_db <- function(
  files,
  tax_format = "auto",
  weight_by_seqs = FALSE,
  plot = TRUE,
  venn_max = 7L,
  verbose = TRUE,
  ...
) {
  if (!is.character(files) || length(files) == 0) {
    stop(
      "`files` must be a non-empty character vector of paths.",
      call. = FALSE
    )
  }
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) {
    stop("File(s) not found: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  diagnosis <- diagnose_db(
    files,
    tax_format = tax_format,
    plot = plot,
    verbose = FALSE,
    ...
  )

  # ---- Extract taxa per rank for every file ------------------------------
  taxa_rows <- list()
  if (verbose) {
    cli::cli_progress_bar(
      format = paste0(
        "{cli::pb_spin} Profiling databases {cli::pb_current}/",
        "{cli::pb_total} | {cli::pb_bar} {cli::pb_percent} | ",
        "ETA: {cli::pb_eta} | {cli::pb_status}"
      ),
      total = length(files),
      clear = FALSE
    )
  }
  for (i in seq_along(files)) {
    if (verbose) {
      cli::cli_progress_update(set = i - 1L, status = basename(files[[i]]))
    }
    taxa_rows[[i]] <- extract_taxa_long_db(files[[i]], tax_format = tax_format)
  }
  if (verbose) {
    cli::cli_progress_update(set = length(files), status = "done")
    cli::cli_progress_done()
  }
  taxa <- dplyr::bind_rows(taxa_rows)

  richness <- compute_richness(taxa)

  # ---- Cross-database comparison (multi-file only) -----------------------
  comparison <- NULL
  comparison_plots <- NULL
  if (length(files) > 1 && nrow(taxa) > 0) {
    comparison <- compare_taxa_across_db(
      taxa,
      weight_by_seqs = weight_by_seqs,
      venn_max = venn_max,
      build_plots = plot
    )
    comparison_plots <- comparison$plots
  }

  # ---- Plots --------------------------------------------------------------
  plots <- list(richness = NULL, comparison = comparison_plots)
  if (plot) {
    if (requireNamespace("ggplot2", quietly = TRUE)) {
      plots$richness <- richness_plot(richness)
    } else {
      cli::cli_alert_info(
        "Package {.pkg ggplot2} is not installed; skipping plots."
      )
    }
  }

  result <- structure(
    list(
      diagnosis = diagnosis,
      taxa = taxa,
      richness = richness,
      comparison = comparison,
      plots = plots
    ),
    class = "dbpq_profile"
  )

  if (verbose) {
    profile_report(result)
  }

  invisible(result)
}


# ——————————————————————————————————————————————————————————————————————
# Internal: taxon extraction
# ——————————————————————————————————————————————————————————————————————

#' Extract a long taxon table (file, rank, taxon, n_seqs) from a FASTA file
#' @keywords internal
extract_taxa_long_db <- function(file, tax_format = "auto") {
  fname <- basename(file)
  lines <- read_lines_db(file)
  headers <- sub("^>", "", lines[grepl("^>", lines)])
  if (length(headers) == 0) {
    return(empty_taxa())
  }

  fmt <- if (tax_format == "auto") {
    detect_tax_format_from_headers(headers)
  } else {
    tax_format
  }
  rank_info <- rank_info_for_format(fmt, headers)
  if (is.null(rank_info)) {
    return(empty_taxa())
  }

  rank_names <- names(rank_info)
  rows <- list()
  for (j in seq_along(rank_info)) {
    if (is.integer(rank_info)) {
      vals <- extract_rank_by_position(headers, position = rank_info[[j]])
    } else {
      prefix <- rank_info[[j]]
      pattern <- paste0(escape_regex(prefix), "[^;,\\s]+")
      vals <- stringr::str_extract(headers, pattern) |>
        stringr::str_remove(paste0("^", escape_regex(prefix)))
    }
    vals <- vals[!is.na(vals) & nzchar(vals)]
    if (length(vals) == 0) {
      next
    }
    counts <- table(vals)
    rows[[length(rows) + 1]] <- tibble::tibble(
      file = fname,
      rank = rank_names[[j]],
      taxon = names(counts),
      n_seqs = as.integer(counts)
    )
  }
  if (length(rows) == 0) {
    return(empty_taxa())
  }
  dplyr::bind_rows(rows)
}


#' An empty long-taxa tibble
#' @keywords internal
empty_taxa <- function() {
  tibble::tibble(
    file = character(0),
    rank = character(0),
    taxon = character(0),
    n_seqs = integer(0)
  )
}


#' Escape regex metacharacters in a literal string
#' @keywords internal
escape_regex <- function(x) {
  gsub("([.\\\\|(){}^$*+?])", "\\\\\\1", x)
}


#' Is ComplexUpset usable with the installed ggplot2?
#'
#' ComplexUpset on CRAN (<= 1.3.3) is incompatible with ggplot2 >= 4.0.0, and
#' merely *loading* such a build registers an `update_ggplot` method that breaks
#' ggplot2 4.0's `+` operator for every package. The fix lives in the GitHub dev
#' version (>= 1.3.6, see krassowski/complex-upset#217). We therefore decide
#' usability from the installed metadata **without loading the namespace**
#' (`system.file()` and `packageVersion()` do not load it): ComplexUpset is
#' considered usable when ggplot2 is older than 4.0.0, or when ComplexUpset is
#' at least 1.3.6.
#' @keywords internal
complexupset_usable <- function() {
  if (!nzchar(system.file(package = "ComplexUpset"))) {
    return(FALSE)
  }
  utils::packageVersion("ggplot2") < "4.0.0" ||
    utils::packageVersion("ComplexUpset") >= "1.3.6"
}


# ——————————————————————————————————————————————————————————————————————
# Internal: richness
# ——————————————————————————————————————————————————————————————————————

#' Per-rank taxonomic richness from a long taxa tibble
#' @keywords internal
compute_richness <- function(taxa) {
  if (nrow(taxa) == 0) {
    return(tibble::tibble(
      file = character(0),
      rank = character(0),
      n_levels = integer(0),
      n_seqs_annotated = integer(0)
    ))
  }
  taxa |>
    dplyr::group_by(.data$file, .data$rank) |>
    dplyr::summarise(
      n_levels = dplyr::n_distinct(.data$taxon),
      n_seqs_annotated = sum(.data$n_seqs),
      .groups = "drop"
    )
}


#' Richness bar plot (distinct taxa per rank, grouped by file)
#' @keywords internal
richness_plot <- function(richness) {
  if (nrow(richness) == 0) {
    return(NULL)
  }
  richness$rank <- factor(richness$rank, levels = order_ranks(unique(richness$rank)))
  ggplot2::ggplot(
    richness,
    ggplot2::aes(
      x = .data$rank,
      y = .data$n_levels,
      fill = .data$file
    )
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge()) +
    ggplot2::labs(
      title = "Taxonomic richness per rank",
      x = "Rank",
      y = "Number of distinct taxa (levels)",
      fill = "Database"
    )
}


# ——————————————————————————————————————————————————————————————————————
# Internal: cross-database comparison
# ——————————————————————————————————————————————————————————————————————

#' Compare taxa across databases, per rank
#'
#' Builds, for each rank, a presence/absence membership table across the
#' databases, the per-signature summary (taxa and sequence totals), and the
#' Venn/UpSet plot.
#' @keywords internal
compare_taxa_across_db <- function(
  taxa,
  weight_by_seqs = FALSE,
  venn_max = 7L,
  build_plots = TRUE
) {
  ranks <- order_ranks(unique(taxa$rank))
  db_labels <- unique(taxa$file)

  # Sequence weighting can only be drawn with a working ComplexUpset; the
  # weighted counts are still returned in `signatures` regardless.
  if (build_plots && weight_by_seqs && !complexupset_usable()) {
    cli::cli_alert_warning(
      paste0(
        "Sequence-weighted UpSet plots need {.pkg ComplexUpset} >= 1.3.6 ",
        "for ggplot2 >= 4.0.0 (install the dev version with ",
        "{.code remotes::install_github('krassowski/complex-upset')}); ",
        "drawing unweighted Venn plots instead. Weighted counts remain in ",
        "{.code $comparison$signatures}."
      )
    )
    weight_by_seqs <- FALSE
  }

  per_db <- taxa |>
    dplyr::group_by(.data$file, .data$rank) |>
    dplyr::summarise(
      n_taxa = dplyr::n_distinct(.data$taxon),
      n_seqs = sum(.data$n_seqs),
      .groups = "drop"
    )

  membership <- list()
  signature_rows <- list()
  plots <- list()

  for (rk in ranks) {
    tr <- taxa[taxa$rank == rk, ]
    # Sequence count per taxon, summed across databases that contain it
    seqs_by_taxon <- tapply(tr$n_seqs, tr$taxon, sum)
    all_taxa <- names(seqs_by_taxon)

    memb <- data.frame(taxon = all_taxa, check.names = FALSE)
    for (db in db_labels) {
      memb[[db]] <- all_taxa %in% tr$taxon[tr$file == db]
    }
    memb$n_seqs <- as.integer(seqs_by_taxon[all_taxa])
    membership[[rk]] <- memb

    # Per-signature aggregation (intersection -> n taxa, n sequences)
    sig <- vapply(
      seq_len(nrow(memb)),
      \(i) {
        present <- db_labels[as.logical(memb[i, db_labels])]
        paste(present, collapse = " & ")
      },
      character(1)
    )
    agg <- data.frame(sig = sig, n_seqs = memb$n_seqs, stringsAsFactors = FALSE)
    sig_tab <- agg |>
      dplyr::group_by(.data$sig) |>
      dplyr::summarise(
        n_taxa = dplyr::n(),
        n_seqs = sum(.data$n_seqs),
        .groups = "drop"
      )
    signature_rows[[rk]] <- tibble::tibble(
      rank = rk,
      members = sig_tab$sig,
      n_members = stringr::str_count(sig_tab$sig, "&") + 1L,
      n_taxa = as.integer(sig_tab$n_taxa),
      n_seqs = as.integer(sig_tab$n_seqs)
    )

    if (build_plots) {
      plots[[rk]] <- comparison_plot_one(
        memb,
        db_labels,
        rank = rk,
        weight_by_seqs = weight_by_seqs,
        venn_max = venn_max
      )
    }
  }

  list(
    per_db = per_db,
    signatures = dplyr::bind_rows(signature_rows),
    membership = membership,
    plots = if (build_plots) plots else NULL
  )
}


#' Build one Venn or UpSet plot for a rank's membership table
#' @keywords internal
comparison_plot_one <- function(
  membership,
  db_labels,
  rank,
  weight_by_seqs = FALSE,
  venn_max = 7L
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    return(NULL)
  }
  upset_ok <- complexupset_usable()
  venn_ok <- requireNamespace("ggVennDiagram", quietly = TRUE)

  # An UpSet needs at least one taxon present in 2+ sets to be meaningful, and
  # ComplexUpset also requires every intersect column to have >= 1 TRUE.
  usable_dbs <- db_labels[vapply(
    db_labels,
    \(d) any(membership[[d]]),
    logical(1)
  )]
  if (length(usable_dbs) < 2) {
    return(NULL)
  }

  too_many_for_venn <- length(usable_dbs) > venn_max
  want_upset <- weight_by_seqs || too_many_for_venn

  if (want_upset && upset_ok) {
    base_ann <- if (weight_by_seqs) {
      list(
        "Sequences" = ggplot2::ggplot(ggplot2::aes(y = .data$n_seqs)) +
          ggplot2::geom_bar(stat = "summary", fun = sum) +
          ggplot2::ylab("Sequences")
      )
    } else {
      NULL
    }
    args <- list(
      data = membership,
      intersect = usable_dbs,
      name = paste0(rank, " (taxa)")
    )
    if (!is.null(base_ann)) {
      args$base_annotations <- base_ann
    }
    return(do.call(ComplexUpset::upset, args))
  }

  # Venn fallback (also used when UpSet was wanted but ComplexUpset is
  # unavailable, provided the number of sets is within ggVennDiagram's limit).
  if (venn_ok && !too_many_for_venn) {
    venn_sets <- lapply(
      usable_dbs,
      \(d) membership$taxon[membership[[d]]]
    )
    names(venn_sets) <- usable_dbs
    return(
      ggVennDiagram::ggVennDiagram(
        venn_sets,
        label = "count",
        label_alpha = 0
      ) +
        ggplot2::scale_fill_gradient(low = "white", high = "#3e135a") +
        ggplot2::labs(title = paste0("Shared taxa at rank '", rank, "'")) +
        ggplot2::theme(legend.position = "none")
    )
  }

  NULL
}


# ——————————————————————————————————————————————————————————————————————
# Internal: report
# ——————————————————————————————————————————————————————————————————————

#' Concise cli report for a database profile
#' @keywords internal
profile_report <- function(x) {
  rich <- x$richness
  cli::cli_h2("Database profile")
  files <- unique(rich$file)
  if (length(files) == 0) {
    cli::cli_alert_warning("No taxonomic ranks could be parsed from the input.")
  }
  for (f in files) {
    rf <- rich[rich$file == f, ]
    cli::cli_alert_info(
      "{.file {f}}: {nrow(rf)} rank{?s}, {sum(rf$n_levels)} distinct taxa total"
    )
  }

  if (!is.null(x$comparison)) {
    cli::cli_h3("Cross-database overlap (distinct taxa per rank)")
    sigs <- x$comparison$signatures
    n_db <- length(unique(x$comparison$per_db$file))
    shared_all <- sigs[sigs$n_members == n_db, ]
    for (rk in unique(sigs$rank)) {
      sa <- shared_all[shared_all$rank == rk, ]
      n_shared <- if (nrow(sa) > 0) {
        sum(sa$n_taxa)
      } else {
        0L
      }
      cli::cli_alert_info("rank {.val {rk}}: {n_shared} taxa shared by all")
    }
  }

  n_issues <- nrow(x$diagnosis$warnings)
  if (n_issues > 0) {
    cli::cli_alert_warning(
      "{n_issues} diagnostic issue{?s} found; see {.code $diagnosis$warnings}."
    )
  }
  invisible(NULL)
}
