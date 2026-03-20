#' Filter a FASTA database by taxonomic pattern
#'
#' @description
#' Filters sequences from a FASTA database whose header lines match a given
#' pattern. Accepts gzip files. May not work on Windows.
#'
#' @param ref_fasta (Character, required) Path to a FASTA file (plain or gzip).
#' @param pattern (Character, required) A pattern to search for in sequence
#'   headers.
#' @param output (Character, required) Path to the output FASTA file
#'   (must not be gzipped).
#' @param force_two_lines_per_seq (Logical, default `TRUE`) Force the FASTA
#'   file to have exactly two lines per sequence (one header, one nucleotide
#'   line). If `FALSE`, the input must already be in this format.
#' @param keep_temporary_files (Logical, default `FALSE`) If `TRUE` and
#'   `force_two_lines_per_seq` is `TRUE`, keep intermediate temporary files.
#'
#' @returns The path to the output file (invisibly).
#' @export
#' @author Adrien Taudière
#' @seealso [count_pattern_db()]
#' @examplesIf tolower(Sys.info()[["sysname"]]) != "windows"
#' db <- system.file("extdata", "example_unite.fasta", package = "dbpq")
#' out <- tempfile(fileext = ".fasta")
#' filter_db(db, "Amanita", output = out)
#' count_seq_db(out)
filter_db <- function(
  ref_fasta,
  pattern,
  output = NULL,
  force_two_lines_per_seq = TRUE,
  keep_temporary_files = FALSE
) {
  if (is.null(output)) {
    stop("You must specify an output file path.")
  }

  if (force_two_lines_per_seq) {
    tmp_file <- tempfile()
    if (is_gzipped(ref_fasta)) {
      system(paste0(
        "zcat ",
        normalizePath(ref_fasta),
        " | sed ':a;N;/>/!s/\\n//;ta;P;D'  > ",
        tmp_file
      ))
    } else {
      system(paste0(
        "cat ",
        normalizePath(ref_fasta),
        " | sed ':a;N;/>/!s/\\n//;ta;P;D'  > ",
        tmp_file
      ))
    }
    ref_fasta <- tmp_file
  }

  if (is_gzipped(ref_fasta)) {
    system(paste0(
      "zcat ",
      normalizePath(ref_fasta),
      " | grep -i '",
      pattern,
      "' ",
      "-A 1 | sed -E 's/--//g' | sed -E '/^$/d' > ",
      output
    ))
  } else {
    system(paste0(
      "cat ",
      normalizePath(ref_fasta),
      " | grep -i '",
      pattern,
      "' ",
      "-A 1 | sed -E 's/--//g' | sed -E '/^$/d' > ",
      output
    ))
  }

  if (force_two_lines_per_seq && !keep_temporary_files) {
    unlink(tmp_file)
  } else if (force_two_lines_per_seq) {
    message(
      "Temporary fasta file with two lines per sequences lives here: ",
      tmp_file
    )
  }
  invisible(normalizePath(output))
}


#' Remove primers from a FASTA database using cutadapt
#'
#' @description
#' Removes pairs of primers and flanking regions from a FASTA reference
#' database using [cutadapt](https://github.com/marcelm/cutadapt/).
#' Uses linked adapters to trim between forward and reverse primers.
#'
#' @param ref_fasta (Character, required) Path to a FASTA file (plain or
#'   gzip).
#' @param output (Character) Path to the output FASTA file. If NULL, defaults
#'   to `{basename}_cutadapted.fasta`.
#' @param primer_fw (Character, required) The forward primer DNA sequence.
#' @param primer_rev (Character, required) The reverse primer DNA sequence.
#' @param discard_untrimmed (Logical, default `TRUE`) Discard sequences where
#'   primers were not found.
#' @param nproc (Integer, default `1`) Number of CPU cores for cutadapt.
#' @param verbose (Logical, default `TRUE`) Print summary statistics.
#' @param cmd_is_run (Logical, default `TRUE`) If FALSE, return the command
#'   string without executing it.
#' @param return_file_path (Logical, default `FALSE`) If TRUE, return the
#'   output file path instead of the command.
#' @param start_with_fw (Logical, default `FALSE`) If TRUE, the forward
#'   primer must be anchored at the start of the sequence.
#' @param output_json (Logical, default `FALSE`) If TRUE, write a JSON
#'   summary of the cutadapt process.
#' @param error_tolerance (Numeric, default `0.1`) Maximum error rate for
#'   primer matching.
#' @param args_before_cutadapt (Character) Shell commands to run before
#'   cutadapt (e.g., conda activation).
#'
#' @returns The cutadapt command string, or the output file path if
#'   `return_file_path = TRUE`.
#' @export
#' @author Adrien Taudière
#' @details
#' This function is mainly a wrapper of the work of others.
#'   Please cite cutadapt (\doi{doi:10.14806/ej.17.1.200}).
#' @examplesIf tolower(Sys.info()[["sysname"]]) != "windows"
#' \dontrun{
#' cutadapt_rm_primers_db(
#'   "database.fasta.gz",
#'   output = "db_cutadapted.fasta",
#'   primer_fw = "GCATCGATGAAGAACGCAGC",
#'   primer_rev = "TCCTCCGCTTATTGATATGC"
#' )
#' }
cutadapt_rm_primers_db <- function(
  ref_fasta,
  output = NULL,
  primer_fw = NULL,
  primer_rev = NULL,
  discard_untrimmed = TRUE,
  nproc = 1,
  verbose = TRUE,
  cmd_is_run = TRUE,
  return_file_path = FALSE,
  start_with_fw = FALSE,
  output_json = FALSE,
  error_tolerance = 0.1,
  args_before_cutadapt = paste0(
    "source ~/miniforge3/etc/profile.d/conda.sh ",
    "&& conda activate cutadaptenv && "
  )
) {
  if (is.null(output)) {
    output <- paste0(basename(file.path(ref_fasta)), "_cutadapted.fasta")
  }

  cmd <- paste0(
    args_before_cutadapt,
    "cutadapt --cores=",
    nproc,
    " -e ",
    error_tolerance,
    " -a '",
    ifelse(start_with_fw, "^", ""),
    primer_fw,
    "...",
    primer_rev,
    "' -o ",
    output
  )

  if (output_json) {
    cmd <- paste0(
      cmd,
      " --json=",
      basename(ref_fasta),
      "_cutadapt.json"
    )
  }

  if (discard_untrimmed) {
    cmd <- paste0(cmd, " --discard-untrimmed")
  }

  cmd <- paste0(cmd, " ", normalizePath(ref_fasta))

  if (cmd_is_run) {
    script_path <- file.path(tempdir(), "script_cutadapt.sh")
    writeLines(cmd, script_path)
    exit_code <- system2("bash", script_path)
    unlink(script_path)
    if (exit_code != 0L) {
      stop(
        "cutadapt failed (exit code ",
        exit_code,
        "). ",
        "Ensure cutadapt is installed and accessible, ",
        "or set `cmd_is_run = FALSE` to inspect the command without",
        " running it.",
        call. = FALSE
      )
    }
    if (verbose) {
      message("Output file is available: ", normalizePath(output))
    }
  } else {
    return(cmd)
  }

  if (verbose) {
    nseq_initial <- count_seq_db(ref_fasta)
    nseq_final <- count_seq_db(output)

    message(
      "The cutadapt process trimmed ",
      nseq_initial - nseq_final,
      " (",
      round((nseq_initial - nseq_final) / nseq_initial * 100, 2),
      "%)",
      " references sequences, for a final number of ",
      nseq_final,
      " references sequences."
    )

    n_nuc_initial <- sum(Biostrings::width(
      Biostrings::readDNAStringSet(ref_fasta)
    ))
    n_nuc_final <- sum(Biostrings::width(
      Biostrings::readDNAStringSet(output)
    ))

    message(
      "The cutadapt process trimmed ",
      n_nuc_initial - n_nuc_final,
      " (",
      round((n_nuc_initial - n_nuc_final) / n_nuc_initial * 100, 2),
      "%)",
      " nucleotides, for a final number of ",
      n_nuc_final,
      " nucleotides.\n The mean width of references sequences is now ",
      round(
        mean(Biostrings::width(
          Biostrings::readDNAStringSet(output)
        )),
        2
      ),
      " vs ",
      round(
        mean(Biostrings::width(
          Biostrings::readDNAStringSet(ref_fasta)
        )),
        2
      ),
      " in the original database."
    )
  }

  if (return_file_path) {
    return(normalizePath(output))
  } else {
    return(cmd)
  }
}
