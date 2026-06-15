# ——————————————————————————————————————————————————————————————————————
# vsearch helpers
# ——————————————————————————————————————————————————————————————————————

#' Find the vsearch executable
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-maturing-blue" alt="lifecycle-maturing"></a>
#'
#' Locates the `vsearch` executable on the system PATH, or verifies a
#' user-supplied path. This is a lightweight standalone version of the
#' helper found in MiscMetabar, so that dbpq does not need to depend on
#' MiscMetabar for vsearch operations.
#'
#' @param path (Character, default `NULL`) Explicit path to the vsearch
#'   executable. If `NULL`, the function searches the system PATH via
#'   [Sys.which()].
#'
#' @returns A character string with the path to vsearch, or `NA` if not
#'   found.
#' @export
#' @seealso [is_vsearch_installed()], [add_sh_to_taxonomy()]
#' @examples
#' find_vsearch()
find_vsearch <- function(path = NULL) {
  if (!is.null(path)) {
    return(path)
  }
  unname(Sys.which("vsearch"))
}


#' Check whether vsearch is installed
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
#' Tests whether the `vsearch` executable is available on the system.
#'
#' @param path (Character, default `NULL`) Explicit path to the vsearch
#'   executable. If `NULL`, the function searches the system PATH.
#'
#' @returns `TRUE` if vsearch is available, `FALSE` otherwise.
#' @export
#' @seealso [find_vsearch()], [add_sh_to_taxonomy()]
#' @examples
#' is_vsearch_installed()
is_vsearch_installed <- function(path = find_vsearch()) {
  !inherits(
    try(
      system2(path, "--version", stdout = TRUE, stderr = TRUE),
      silent = TRUE
    ),
    "try-error"
  )
}


# ——————————————————————————————————————————————————————————————————————
# add_sh_to_taxonomy()
# ——————————————————————————————————————————————————————————————————————

#' Annotate query sequences with UNITE Species Hypothesis (SH) names
#'
#' @description
#' <a href="https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle">
#' <img src="https://img.shields.io/badge/lifecycle-experimental-orange" alt="lifecycle-experimental"></a>
#'
#' `r lifecycle::badge("experimental")`
#'
#' Runs `vsearch --usearch_global` to match query sequences against a
#' UNITE reference database, then extracts the Species Hypothesis (SH)
#' identifier from each best hit. The SH name is the first `|`-delimited
#' field in UNITE sequence identifiers (e.g. `SH123456.09FU`).
#'
#' This function ports the logic of the nf-core/ampliseq
#' `add_sh_to_taxonomy.py` script into R, using vsearch directly
#' instead of requiring external lookup tables.
#'
#' @param query_fasta (Character) Path to a FASTA file containing the
#'   query sequences (e.g. ASVs or OTUs).
#' @param unite_db (Character) Path to a UNITE reference FASTA file.
#'   The file can be in any format (SINTAX, UNITE default, etc.) as long
#'   as the sequence identifiers contain SH names as the first
#'   `|`-delimited field. Files downloaded via [download_unite_db()] meet
#'   this requirement.
#' @param vsearchpath (Character) Path to the vsearch executable.
#'   Defaults to [find_vsearch()].
#' @param id (Numeric, default `0.97`) Minimum sequence identity
#'   threshold (0–1) for vsearch `--id` parameter.
#' @param maxaccepts (Integer, default `1`) Maximum number of hits to
#'   accept per query. Set to `0` for unlimited hits (useful when
#'   multiple equally-good matches may have different SH names).
#' @param maxrejects (Integer, default `32`) Maximum number of
#'   rejected hits before stopping the search for a query.
#' @param nproc (Integer, default `1`) Number of threads for vsearch.
#' @param top_hits_only (Logical, default `TRUE`) If `TRUE`, only
#'   report the top hit per query (highest identity). If `FALSE`,
#'   report all accepted hits, which is useful for detecting
#'   ambiguous SH assignments.
#' @param keep_temporary_files (Logical, default `FALSE`) If `TRUE`,
#'   do not delete the temporary blast6 output file after parsing.
#' @param verbose (Logical, default `FALSE`) Print vsearch progress
#'   messages.
#'
#' @returns A data.frame with columns:
#'   \itemize{
#'     \item \code{query}: Query sequence identifier.
#'     \item \code{sh_name}: Species Hypothesis name extracted from the
#'       best database hit (e.g. `SH123456.09FU`), or \code{NA} if no
#'       hit was found.
#'     \item \code{target}: Full identifier of the matched database
#'       sequence.
#'     \item \code{pct_id}: Percent identity of the match.
#'     \item \code{aln_len}: Alignment length.
#'     \item \code{mismatches}: Number of mismatches.
#'     \item \code{e_value}: E-value of the match.
#'     \item \code{is_ambiguous}: Logical; `TRUE` if multiple hits with
#'       the same top identity disagree on the SH name.
#'   }
#' @export
#' @author Adrien Taudière
#' @seealso [download_unite_db()], [is_vsearch_installed()],
#'   [find_vsearch()]
#' @examples
#' \dontrun{
#' # Download a UNITE database first
#' unite_file <- download_unite_db(
#'   version = "10.0",
#'   taxonomic_format = "sintax",
#'   taxon_group = "fungi"
#' )
#'
#' # Annotate ASVs with SH names
#' sh_res <- add_sh_to_taxonomy(
#'   query_fasta = "asvs.fasta",
#'   unite_db = unite_file,
#'   id = 0.97
#' )
#' head(sh_res)
#'
#' # Check for ambiguous assignments
#' sh_res[sh_res$is_ambiguous, ]
#' }
add_sh_to_taxonomy <- function(
  query_fasta,
  unite_db,
  vsearchpath = find_vsearch(),
  id = 0.97,
  maxaccepts = 1,
  maxrejects = 32,
  nproc = 1,
  top_hits_only = TRUE,
  keep_temporary_files = FALSE,
  verbose = FALSE
) {
  if (!is_vsearch_installed(vsearchpath)) {
    stop(
      "vsearch is not found at '",
      vsearchpath,
      "'. ",
      "Install vsearch or provide the path via the vsearchpath argument.",
      call. = FALSE
    )
  }

  if (!file.exists(query_fasta)) {
    stop("Query FASTA file not found: ", query_fasta, call. = FALSE)
  }

  if (!file.exists(unite_db)) {
    stop("UNITE database file not found: ", unite_db, call. = FALSE)
  }

  # Temporary output file for blast6 format
  blast6_file <- tempfile(pattern = "dbpq_blast6_", fileext = ".txt")
  on.exit(
    if (!keep_temporary_files && file.exists(blast6_file)) {
      unlink(blast6_file)
    },
    add = TRUE
  )

  # Build vsearch command
  # --blast6out format: query target pctId alnLen mismatches gapOpens qStart qEnd tStart tEnd eValue bitScore
  cmd_args <- paste0(
    " --usearch_global ",
    shQuote(query_fasta),
    " --db ",
    shQuote(unite_db),
    " --id ",
    id,
    " --maxaccepts ",
    maxaccepts,
    " --maxrejects ",
    maxrejects,
    " --blast6out ",
    shQuote(blast6_file),
    " --threads ",
    nproc,
    " --notrunclabels"
  )

  if (verbose) {
    message("Running vsearch --usearch_global...")
    message(paste0(vsearchpath, cmd_args))
  }

  vsearch_output <- system2(
    vsearchpath,
    args = cmd_args,
    stdout = TRUE,
    stderr = if (verbose) "" else FALSE
  )

  vsearch_status <- attr(vsearch_output, "status")
  if (!is.null(vsearch_status) && vsearch_status != 0) {
    stop(
      "vsearch --usearch_global failed with status ",
      vsearch_status,
      ".\n",
      paste(vsearch_output, collapse = "\n"),
      call. = FALSE
    )
  }

  if (!file.exists(blast6_file) || file.info(blast6_file)$size == 0) {
    if (verbose) {
      message("No matches found by vsearch.")
    }
    return(data.frame(
      query = character(0),
      sh_name = character(0),
      target = character(0),
      pct_id = numeric(0),
      aln_len = integer(0),
      mismatches = integer(0),
      e_value = numeric(0),
      is_ambiguous = logical(0),
      stringsAsFactors = FALSE
    ))
  }

  # Parse blast6 output
  # Columns: query, target, pct_id, aln_len, mismatches, gap_opens,
  #          q_start, q_end, t_start, t_end, e_value, bit_score
  blast6 <- read.table(
    blast6_file,
    sep = "\t",
    header = FALSE,
    stringsAsFactors = FALSE
  )
  colnames(blast6) <- c(
    "query",
    "target",
    "pct_id",
    "aln_len",
    "mismatches",
    "gap_opens",
    "q_start",
    "q_end",
    "t_start",
    "t_end",
    "e_value",
    "bit_score"
  )

  # Extract SH name from target identifier.
  # UNITE headers: "SH123456.09FU|species_name|..." or
  #                "SH123456.09FU;tax=..." (SINTAX format)
  # The SH name is the first | or ; delimited part.
  blast6$sh_name <- vapply(
    blast6$target,
    function(target_id) {
      # Remove everything after | or ;
      sh <- strsplit(target_id, "[|;]")[[1]][1]
      # Verify it looks like an SH identifier (SH + digits + . + digits + FU)
      if (grepl("^SH[0-9]+\\.[0-9]+FU", sh)) {
        sh
      } else {
        NA_character_
      }
    },
    character(1)
  )

  if (top_hits_only) {
    # Keep only the best hit per query (highest pct_id, then longest aln_len)
    blast6 <- blast6[order(blast6$query, -blast6$pct_id, -blast6$aln_len), ]
    blast6 <- blast6[!duplicated(blast6$query), ]
    blast6$is_ambiguous <- FALSE
  } else {
    # Detect ambiguous assignments: queries with multiple top hits
    # that disagree on the SH name
    blast6 <- blast6[order(blast6$query, -blast6$pct_id, -blast6$aln_len), ]

    # For each query, check if top hits (same pct_id) disagree on SH
    blast6$is_ambiguous <- FALSE
    queries <- unique(blast6$query)
    for (q in queries) {
      idx <- which(blast6$query == q)
      top_pct <- blast6$pct_id[idx[1]]
      top_idx <- idx[blast6$pct_id[idx] == top_pct]
      sh_vals <- unique(blast6$sh_name[top_idx])
      sh_vals <- sh_vals[!is.na(sh_vals)]
      if (length(sh_vals) > 1) {
        blast6$is_ambiguous[top_idx] <- TRUE
      }
    }
  }

  # Select and order output columns
  result <- blast6[, c(
    "query",
    "sh_name",
    "target",
    "pct_id",
    "aln_len",
    "mismatches",
    "e_value",
    "is_ambiguous"
  )]
  rownames(result) <- NULL

  if (verbose) {
    n_matched <- sum(!is.na(result$sh_name))
    n_ambiguous <- sum(result$is_ambiguous)
    n_total <- length(unique(result$query))
    message(
      "SH annotation complete: ",
      n_matched,
      "/",
      n_total,
      " queries matched, ",
      n_ambiguous,
      " ambiguous assignments."
    )
  }

  return(result)
}
