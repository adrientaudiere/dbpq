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
#' @param file_path (Character, required) Path to a file.
#'
#' @returns A character vector of file extensions.
#' @export
#' @examples
#' get_file_extension("my_database.fasta")
#' get_file_extension("my_database.fasta.gz")
get_file_extension <- function(file_path) {
  if (stringr::str_count(file_path, "\\.") == 0) {
    stop("There is no '.' inside your file path: ", file_path)
  }
  if (stringr::str_count(file_path, "\\.") > 1) {
    warning("There is more than one '.' inside your file path: ", file_path)
  }
  file_ext <- strsplit(basename(file_path), ".", fixed = TRUE)[[1]][-1]
  return(file_ext)
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
