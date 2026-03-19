#' Format taxonomy headers to SINTAX format
#'
#' @description
#' Converts taxonomy headers from the common `k__Kingdom;p__Phylum;...`
#' format to the VSEARCH SINTAX format (`tax=k:Kingdom,p:Phylum,...`).
#'
#' @param fasta_db (Character) Path to a FASTA file. Mutually exclusive
#'   with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings. Mutually
#'   exclusive with `fasta_db`.
#' @param pattern_tax (Character, default `"k__"`) Pattern identifying the
#'   start of taxonomy in the original format.
#' @param pattern_sintax (Character, default `"tax=k:"`) Pattern for the
#'   start of taxonomy in SINTAX format.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path.
#'
#' @returns If `taxnames` is used, a character vector of reformatted names.
#'   If `fasta_db` is used, a `DNAStringSet` with reformatted names.
#' @export
#' @author Adrien Taudière
#' @seealso [format2dada2()], [format2dada2_species()]
#' @examples
#' format2sintax(taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes")
format2sintax <- function(
  fasta_db = NULL,
  taxnames = NULL,
  pattern_tax = "k__",
  pattern_sintax = "tax=k:",
  output_path = NULL
) {
  if (is.null(taxnames) && is.null(fasta_db)) {
    stop("You must specify taxnames or fasta_db parameter.")
  } else if (!is.null(taxnames) && !is.null(fasta_db)) {
    stop("You must specify either taxnames or fasta_db, not both.")
  } else if (!is.null(taxnames)) {
    new_names <- taxnames |>
      (\(x) gsub(";", ",", x))() |>
      (\(x) gsub(pattern_tax, paste0(";", pattern_sintax), x))() |>
      (\(x) gsub("__", ":", x))() |>
      (\(x) gsub(";;", ";", x))() |>
      (\(x) {
        gsub(
          paste0(",", pattern_sintax),
          paste0(";", pattern_sintax),
          x
        )
      })()
    return(new_names)
  } else if (!is.null(fasta_db)) {
    dna <- Biostrings::readDNAStringSet(fasta_db)
    new_names <- names(dna) |>
      (\(x) gsub(";", ",", x))() |>
      (\(x) gsub(pattern_tax, paste0(";", pattern_sintax), x))() |>
      (\(x) gsub("__", ":", x))() |>
      (\(x) gsub(";;", ";", x))() |>
      (\(x) {
        gsub(
          paste0(",", pattern_sintax),
          paste0(";", pattern_sintax),
          x
        )
      })()

    names(dna) <- new_names
    if (!is.null(output_path)) {
      Biostrings::writeXStringSet(dna, filepath = output_path)
    }
    return(dna)
  }
}


#' Format taxonomy headers for dada2::assignTaxonomy
#'
#' @description
#' Converts taxonomy headers to the format expected by
#' `dada2::assignTaxonomy()`: `Kingdom;Phylum;Class;Order;Family;Genus;`.
#'
#' @param fasta_db (Character) Path to a FASTA file. Mutually exclusive
#'   with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings. Mutually
#'   exclusive with `fasta_db`.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path.
#' @param from_sintax (Logical, default `TRUE`) If TRUE, input is in SINTAX
#'   format. If FALSE, input is converted from standard format via
#'   [format2sintax()] first.
#' @param pattern_to_remove (Character) Optional regex pattern to remove
#'   from the reformatted names.
#' @param ... Additional arguments passed to [format2sintax()] when
#'   `from_sintax = FALSE`.
#'
#' @returns If `taxnames` is used, a character vector. If `fasta_db` is used,
#'   a `DNAStringSet` with reformatted names. When `output_path` is provided,
#'   the FASTA file is written and the `DNAStringSet` is returned invisibly.
#' @export
#' @author Adrien Taudière
#' @seealso [format2sintax()], [format2dada2_species()]
#' @examples
#' format2dada2(
#'   taxnames = "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes",
#'   from_sintax = TRUE
#' )
format2dada2 <- function(
  fasta_db = NULL,
  taxnames = NULL,
  output_path = NULL,
  from_sintax = TRUE,
  pattern_to_remove = NULL,
  ...
) {
  if (is.null(taxnames) && is.null(fasta_db)) {
    stop("You must specify taxnames or fasta_db parameter.")
  } else if (!is.null(taxnames) && !is.null(fasta_db)) {
    stop("You must specify either taxnames or fasta_db, not both.")
  } else if (!is.null(taxnames)) {
    if (from_sintax) {
      new_names <- taxnames
    } else {
      new_names <- format2sintax(taxnames = taxnames, ...)
    }
    new_names <- new_names |>
      stringr::str_split_fixed(";tax=", n = 2) |>
      tibble::as_tibble(.name_repair = "universal") |>
      tidyr::unite(taxnames, c(...2, ...1), sep = ";") |>
      dplyr::pull(taxnames) |>
      (\(x) gsub(":", "__", x))() |>
      (\(x) gsub(",", ";", x))()

    if (!is.null(pattern_to_remove)) {
      new_names <- new_names |>
        stringr::str_remove(pattern_to_remove)
    }

    return(new_names)
  } else if (!is.null(fasta_db)) {
    dna <- Biostrings::readDNAStringSet(fasta_db)
    if (from_sintax) {
      new_names <- names(dna)
    } else {
      new_names <- format2sintax(taxnames = names(dna), ...)
    }

    new_names <- purrr::map_chr(
      new_names,
      \(x) {
        nb_char <- stringr::str_count(x, ":")
        max_char <- max(stringr::str_count(new_names, ":"))
        diff <- max_char - nb_char - 2
        if (diff > 0) {
          paste0(x, strrep(",", diff))
        } else {
          x
        }
      }
    )

    new_names <- new_names |>
      stringr::str_split_fixed(";tax=", n = 2) |>
      tibble::as_tibble(.name_repair = "universal_quiet") |>
      tidyr::unite(taxnames, c(...2, ...1), sep = "") |>
      dplyr::pull(taxnames) |>
      paste0(";") |>
      gsub(pattern = ":", replacement = "__") |>
      gsub(pattern = ",", replacement = ";")

    if (!is.null(pattern_to_remove)) {
      new_names <- new_names |>
        stringr::str_remove(pattern_to_remove)
    }

    names(dna) <- new_names

    if (!is.null(output_path)) {
      Biostrings::writeXStringSet(dna, filepath = output_path)
      invisible(dna)
    } else {
      return(dna)
    }
  }
}


#' Format taxonomy headers for dada2::addSpecies
#'
#' @description
#' Converts taxonomy headers to the format expected by
#' `dada2::addSpecies()`: `AccessionID Genus Species`.
#'
#' @param fasta_db (Character) Path to a FASTA file. Mutually exclusive
#'   with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings. Mutually
#'   exclusive with `fasta_db`.
#' @param from_sintax (Logical, default `FALSE`) If TRUE, input is in
#'   SINTAX format. If FALSE, input uses standard `k__` format.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path.
#' @param ... Additional arguments passed to internal functions.
#'
#' @returns If `taxnames` is used, a character vector. If `fasta_db` is used,
#'   a `DNAStringSet` with reformatted names.
#' @export
#' @author Adrien Taudière
#' @seealso [format2dada2()], [format2sintax()]
#' @examples
#' format2dada2_species(
#'   taxnames = "AB123;k__Fungi;g__Aspergillus;s__fumigatus",
#'   from_sintax = FALSE
#' )
format2dada2_species <- function(
  fasta_db = NULL,
  taxnames = NULL,
  from_sintax = FALSE,
  output_path = NULL,
  ...
) {
  if (is.null(taxnames) && is.null(fasta_db)) {
    stop("You must specify taxnames or fasta_db parameter.")
  } else if (!is.null(taxnames) && !is.null(fasta_db)) {
    stop("You must specify either taxnames or fasta_db, not both.")
  } else if (!is.null(taxnames)) {
    if (from_sintax) {
      new_names <- paste(
        stringr::str_extract(taxnames, "^(.*?);tax=", group = TRUE),
        stringr::str_extract(taxnames, "g:(.*?),", group = TRUE),
        stringr::str_extract(taxnames, "s:(.*?)$", group = TRUE),
        sep = " "
      )
    } else {
      new_names <- paste(
        stringr::str_extract(taxnames, "^(.*?)k__", group = TRUE),
        stringr::str_extract(taxnames, "g__(.*?);", group = TRUE),
        stringr::str_extract(taxnames, "s__(.*?)$", group = TRUE),
        sep = " "
      )
    }
    return(new_names)
  } else if (!is.null(fasta_db)) {
    dna <- Biostrings::readDNAStringSet(fasta_db)
    taxnames_vec <- names(dna)
    if (from_sintax) {
      id <- stringr::str_extract(taxnames_vec, "^(.*?);tax=", group = TRUE)
      id[is.na(id)] <- taxnames_vec[is.na(id)]
      genus <- stringr::str_extract(taxnames_vec, "g:(.*?),", group = TRUE)
      species <- stringr::str_extract(taxnames_vec, "s:(.*?)$", group = TRUE)
    } else {
      id <- stringr::str_extract(taxnames_vec, "^(.*?)k__", group = TRUE)
      id[is.na(id)] <- taxnames_vec[is.na(id)]
      genus <- stringr::str_extract(taxnames_vec, "g__(.*?);", group = TRUE)
      species <- stringr::str_extract(taxnames_vec, "s__(.*?)$", group = TRUE)
    }
    new_names <- paste(id, genus, species, sep = " ")

    names(dna) <- new_names
    names(dna)[is.na(names(dna))] <- taxnames_vec[is.na(names(dna))]

    if (!is.null(output_path)) {
      Biostrings::writeXStringSet(dna, filepath = output_path)
    }
    return(dna)
  }
}
