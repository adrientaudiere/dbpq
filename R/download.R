#' Download a UNITE reference database
#'
#' @description
#' Downloads the latest UNITE fungal ITS database for taxonomic assignment.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param type (Character, default `"dynamic"`) One of `"dynamic"` or
#'   `"static"`. Dynamic files include singletons, static do not.
#' @param taxon_group (Character, default `"fungi"`) One of `"fungi"` or
#'   `"eukaryotes"`.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @examples
#' \dontrun{
#' download_unite_db()
#' }
download_unite_db <- function(
  dest_dir = ".",
  type = c("dynamic", "static"),
  taxon_group = c("fungi", "eukaryotes"),
  verbose = TRUE
) {
  type <- match.arg(type)
  taxon_group <- match.arg(taxon_group)

  stop(
    "download_unite_db() is not yet implemented. ",
    "UNITE requires manual download from https://unite.ut.ee/repository.php"
  )
}


#' Download a SILVA reference database
#'
#' @description
#' Downloads the SILVA ribosomal RNA database (16S/18S).
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character) SILVA version number (e.g., `"138.2"`).
#' @param target (Character, default `"SSU"`) One of `"SSU"` or `"LSU"`.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @examples
#' \dontrun{
#' download_silva_db()
#' }
download_silva_db <- function(
  dest_dir = ".",
  version = NULL,
  target = c("SSU", "LSU"),
  verbose = TRUE
) {
  target <- match.arg(target)

  stop(
    "download_silva_db() is not yet implemented. ",
    "Download manually from https://www.arb-silva.de/download/arb-files/"
  )
}


#' Download a PR2 reference database
#'
#' @description
#' Downloads the PR2 protist ribosomal reference database.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character) PR2 version number.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @examples
#' \dontrun{
#' download_pr2_db()
#' }
download_pr2_db <- function(
  dest_dir = ".",
  version = NULL,
  verbose = TRUE
) {
  stop(
    "download_pr2_db() is not yet implemented. ",
    "Download manually from https://pr2-database.org/"
  )
}


#' Download a BOLD reference database
#'
#' @description
#' Downloads reference sequences from BOLD Systems (Barcode of Life Data).
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param marker (Character, default `"COI-5P"`) The barcode marker to
#'   download.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @examples
#' \dontrun{
#' download_bold_db()
#' }
download_bold_db <- function(
  dest_dir = ".",
  marker = "COI-5P",
  verbose = TRUE
) {
  stop(
    "download_bold_db() is not yet implemented. ",
    "Download manually from https://www.boldsystems.org/"
  )
}


#' Download the MaarjAM reference database
#'
#' @description
#' Downloads the MaarjAM database for arbuscular mycorrhizal fungi (AMF).
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @examples
#' \dontrun{
#' download_marjaam_db()
#' }
download_marjaam_db <- function(
  dest_dir = ".",
  verbose = TRUE
) {
  stop(
    "download_marjaam_db() is not yet implemented. ",
    "Download manually from https://maarjam.ut.ee/"
  )
}


#' Download the Eukaryome reference database
#'
#' @description
#' Downloads the Eukaryome database.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @examples
#' \dontrun{
#' download_eukaryome_db()
#' }
download_eukaryome_db <- function(
  dest_dir = ".",
  verbose = TRUE
) {
  stop(
    "download_eukaryome_db() is not yet implemented. ",
    "Download manually from https://eukaryome.org/"
  )
}
