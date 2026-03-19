# ——————————————————————————————————————————————————————————————————————
# Internal: parse / render taxonomy headers
# ——————————————————————————————————————————————————————————————————————

# Parse a single FASTA header string (with or without leading ">") into a
# named list: id (character) + ranks (named character vector, e.g. c(k="Fungi")).
# Supported formats: "sintax", "unite", "greengenes2".
.parse_tax_header <- function(header, format) {
  h <- sub("^>", "", header)

  if (format == "sintax") {
    m <- regexpr(";tax=", h, fixed = TRUE)
    if (m < 0) {
      return(list(id = h, ranks = character(0)))
    }
    id <- substr(h, 1, m - 1L)
    rank_str <- substr(h, m + 5L, nchar(h))
    rank_pairs <- strsplit(rank_str, ",", fixed = TRUE)[[1]]
    keys <- vapply(
      rank_pairs,
      \(rp) strsplit(rp, ":", fixed = TRUE)[[1]][1],
      character(1)
    )
    vals <- vapply(
      rank_pairs,
      \(rp) {
        kv <- strsplit(rp, ":", fixed = TRUE)[[1]]
        if (length(kv) > 1L) kv[2L] else NA_character_
      },
      character(1)
    )
    ranks <- stats::setNames(vals, keys)
    list(id = id, ranks = ranks)
  } else if (format %in% c("unite", "greengenes2")) {
    if (format == "unite") {
      parts <- strsplit(h, ";", fixed = TRUE)[[1]]
      id <- parts[1L]
      rank_parts <- parts[-1L]
    } else {
      # greengenes2: space separates ID from taxonomy string
      space_pos <- regexpr("\\s", h)
      if (space_pos < 0L) {
        return(list(id = h, ranks = character(0)))
      }
      id <- substr(h, 1L, space_pos - 1L)
      tax_str <- trimws(substr(h, space_pos + 1L, nchar(h)))
      rank_parts <- strsplit(tax_str, ";", fixed = TRUE)[[1]]
    }
    keys <- vapply(
      rank_parts,
      \(rp) strsplit(rp, "__", fixed = TRUE)[[1]][1L],
      character(1)
    )
    vals <- vapply(
      rank_parts,
      \(rp) {
        kv <- strsplit(rp, "__", fixed = TRUE)[[1]]
        if (length(kv) > 1L) paste(kv[-1L], collapse = "__") else NA_character_
      },
      character(1)
    )
    ranks <- stats::setNames(vals, keys)
    list(id = id, ranks = ranks)
  } else {
    stop(
      "Unsupported input format: '",
      format,
      "'. ",
      "Use one of: 'sintax', 'unite', 'greengenes2'."
    )
  }
}


# Render a parsed header (list with id + ranks) to the target format string
# (without leading ">").
.render_tax_header <- function(parsed, format) {
  id <- parsed$id
  ranks <- parsed$ranks

  if (format == "sintax") {
    if (length(ranks) == 0L) {
      return(id)
    }
    rank_str <- paste(paste0(names(ranks), ":", ranks), collapse = ",")
    paste0(id, ";tax=", rank_str)
  } else if (format == "unite") {
    if (length(ranks) == 0L) {
      return(id)
    }
    rank_str <- paste(paste0(names(ranks), "__", ranks), collapse = ";")
    paste0(id, ";", rank_str)
  } else if (format == "greengenes2") {
    if (length(ranks) == 0L) {
      return(id)
    }
    rank_str <- paste(paste0(names(ranks), "__", ranks), collapse = ";")
    paste0(id, " ", rank_str)
  } else if (format == "dada2") {
    # Unprefixed semicolon-separated taxonomy, trailing semicolon, no ID
    if (length(ranks) == 0L) {
      return(paste0(id, ";"))
    }
    paste0(paste(ranks, collapse = ";"), ";")
  } else if (format == "dada2_species") {
    # "ID Genus Species" for dada2::addSpecies()
    g <- ranks[names(ranks) == "g"]
    s <- ranks[names(ranks) == "s"]
    if (length(g) == 0L || is.na(g)) {
      g <- ""
    }
    if (length(s) == 0L || is.na(s)) {
      s <- ""
    }
    paste(id, g, s)
  } else {
    stop(
      "Unsupported output format: '",
      format,
      "'. ",
      "Use one of: 'sintax', 'unite', 'greengenes2', 'dada2', 'dada2_species'."
    )
  }
}


# Detect format from a plain text string (not a file path).
.detect_tax_format_str <- function(text) {
  if (grepl("tax=", text, fixed = TRUE)) {
    return("sintax")
  }
  if (grepl("d__", text, fixed = TRUE)) {
    return("greengenes2")
  }
  if (grepl("k__", text, fixed = TRUE)) {
    return("unite")
  }
  "unknown"
}


# ——————————————————————————————————————————————————————————————————————
# format_fasta_db(): unified conversion function
# ——————————————————————————————————————————————————————————————————————

#' Convert a FASTA database to a specified taxonomy format
#'
#' @description
#' Detects (or uses) the input taxonomy format and rewrites sequence headers
#' to the requested output format. This is the primary conversion function;
#' [format2sintax()], [format2dada2()], and [format2dada2_species()] are
#' convenience wrappers around it.
#'
#' Supported **input** formats (prefix-based, with detectable rank labels):
#' `"sintax"`, `"unite"`, `"greengenes2"`.
#'
#' Supported **output** formats:
#' - `"sintax"` — VSEARCH/USEARCH SINTAX (`>ID;tax=k:Kingdom,p:Phylum,...`)
#' - `"unite"` — UNITE default (`>ID;k__Kingdom;p__Phylum;...`)
#' - `"greengenes2"` — Greengenes2 (`>ID d__Domain;p__Phylum;...`)
#' - `"dada2"` — Unprefixed semicolon-delimited (`>Kingdom;Phylum;...;`)
#' - `"dada2_species"` — For `dada2::addSpecies()` (`>ID Genus Species`)
#'
#' Positional formats (`"pr2"`, `"dada2"`) can be detected by
#' [detect_tax_format()] but cannot be used as input for conversion because
#' they lack rank labels.
#'
#' @param fasta_db (Character) Path to a FASTA file (plain or gzipped).
#'   Mutually exclusive with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings (without
#'   leading `>`). Mutually exclusive with `fasta_db`.
#' @param output_format (Character) Target format. One of `"sintax"`,
#'   `"unite"`, `"greengenes2"`, `"dada2"`, `"dada2_species"`.
#' @param input_format (Character, default `"auto"`) Input format. One of
#'   `"auto"` (auto-detect via [detect_tax_format()]), `"sintax"`,
#'   `"unite"`, `"greengenes2"`.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path and return the `DNAStringSet`
#'   invisibly.
#'
#' @returns If `taxnames` is used, a character vector of reformatted headers.
#'   If `fasta_db` is used, a `DNAStringSet` with reformatted names
#'   (invisibly when `output_path` is given).
#' @export
#' @author Adrien Taudière
#' @seealso [detect_tax_format()], [format2sintax()], [format2dada2()],
#'   [format2dada2_species()]
#' @examples
#' # UNITE → SINTAX
#' format_fasta_db(
#'   taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes",
#'   output_format = "sintax"
#' )
#'
#' # SINTAX → UNITE
#' format_fasta_db(
#'   taxnames = "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes",
#'   output_format = "unite"
#' )
#'
#' # Greengenes2 → dada2
#' format_fasta_db(
#'   taxnames = "abc123 d__Bacteria;p__Pseudomonadota;g__Escherichia",
#'   output_format = "dada2"
#' )
format_fasta_db <- function(
  fasta_db = NULL,
  taxnames = NULL,
  output_format = c("sintax", "unite", "greengenes2", "dada2", "dada2_species"),
  input_format = "auto",
  output_path = NULL
) {
  output_format <- match.arg(output_format)

  if (is.null(taxnames) && is.null(fasta_db)) {
    stop("You must specify taxnames or fasta_db parameter.")
  }
  if (!is.null(taxnames) && !is.null(fasta_db)) {
    stop("You must specify either taxnames or fasta_db, not both.")
  }

  if (!is.null(taxnames)) {
    if (input_format == "auto") {
      input_format <- .detect_tax_format_str(paste(taxnames, collapse = " "))
      if (input_format == "unknown") {
        stop(
          "Cannot auto-detect input format from taxnames. ",
          "Please specify `input_format`."
        )
      }
    }
    parsed <- lapply(taxnames, .parse_tax_header, format = input_format)
    vapply(parsed, \(p) .render_tax_header(p, output_format), character(1))
  } else {
    if (input_format == "auto") {
      input_format <- detect_tax_format(fasta_db)
      if (input_format == "unknown") {
        stop(
          "Cannot auto-detect input format. ",
          "Please specify `input_format`."
        )
      }
    }
    dna <- Biostrings::readDNAStringSet(fasta_db)
    parsed <- lapply(names(dna), .parse_tax_header, format = input_format)
    new_names <- vapply(
      parsed,
      \(p) .render_tax_header(p, output_format),
      character(1)
    )
    names(dna) <- new_names
    if (!is.null(output_path)) {
      Biostrings::writeXStringSet(dna, filepath = output_path)
      invisible(dna)
    } else {
      dna
    }
  }
}


# ——————————————————————————————————————————————————————————————————————
# format2sintax(), format2dada2(), format2dada2_species()
# ——————————————————————————————————————————————————————————————————————

#' Format taxonomy headers to SINTAX format
#'
#' @description
#' Converts taxonomy headers to the VSEARCH SINTAX format
#' (`>ID;tax=k:Kingdom,p:Phylum,...`). Wrapper around [format_fasta_db()].
#'
#' @param fasta_db (Character) Path to a FASTA file. Mutually exclusive
#'   with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings (without
#'   leading `>`). Mutually exclusive with `fasta_db`.
#' @param input_format (Character, default `"auto"`) Input taxonomy format.
#'   One of `"auto"`, `"unite"`, `"greengenes2"`, `"sintax"`.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path.
#'
#' @returns If `taxnames` is used, a character vector of reformatted names.
#'   If `fasta_db` is used, a `DNAStringSet` with reformatted names.
#' @export
#' @author Adrien Taudière
#' @seealso [format_fasta_db()], [format2dada2()], [format2dada2_species()]
#' @examples
#' # UNITE format → SINTAX
#' format2sintax(taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes")
#'
#' # Greengenes2 format → SINTAX
#' format2sintax(
#'   taxnames = "abc123 d__Bacteria;p__Pseudomonadota",
#'   input_format = "greengenes2"
#' )
format2sintax <- function(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL
) {
  format_fasta_db(
    fasta_db = fasta_db,
    taxnames = taxnames,
    output_format = "sintax",
    input_format = input_format,
    output_path = output_path
  )
}


#' Format taxonomy headers for dada2::assignTaxonomy
#'
#' @description
#' Converts taxonomy headers to the format expected by
#' `dada2::assignTaxonomy()`: unprefixed semicolon-delimited taxonomy
#' (`>Kingdom;Phylum;Class;Order;Family;Genus;`). Wrapper around
#' [format_fasta_db()].
#'
#' @param fasta_db (Character) Path to a FASTA file. Mutually exclusive
#'   with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings (without
#'   leading `>`). Mutually exclusive with `fasta_db`.
#' @param input_format (Character, default `"auto"`) Input taxonomy format.
#'   One of `"auto"`, `"sintax"`, `"unite"`, `"greengenes2"`.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path. The `DNAStringSet` is returned
#'   invisibly.
#' @param pattern_to_remove (Character) Optional regex pattern to remove
#'   from the reformatted names (applied after conversion).
#'
#' @returns If `taxnames` is used, a character vector. If `fasta_db` is
#'   used, a `DNAStringSet` with reformatted names. When `output_path` is
#'   provided, returned invisibly.
#' @export
#' @author Adrien Taudière
#' @seealso [format_fasta_db()], [format2sintax()], [format2dada2_species()]
#' @examples
#' # SINTAX format → dada2
#' format2dada2(
#'   taxnames = "AB123;tax=k:Fungi,p:Ascomycota,c:Sordariomycetes"
#' )
#'
#' # UNITE format → dada2
#' format2dada2(
#'   taxnames = "AB123;k__Fungi;p__Ascomycota;c__Sordariomycetes",
#'   input_format = "unite"
#' )
format2dada2 <- function(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL,
  pattern_to_remove = NULL
) {
  result <- format_fasta_db(
    fasta_db = fasta_db,
    taxnames = taxnames,
    output_format = "dada2",
    input_format = input_format,
    output_path = output_path
  )
  if (!is.null(pattern_to_remove)) {
    if (is.character(result)) {
      result <- stringr::str_remove(result, pattern_to_remove)
    } else {
      names(result) <- stringr::str_remove(names(result), pattern_to_remove)
    }
  }
  result
}


#' Format taxonomy headers for dada2::addSpecies
#'
#' @description
#' Converts taxonomy headers to the format expected by
#' `dada2::addSpecies()`: `ID Genus Species`. Wrapper around
#' [format_fasta_db()].
#'
#' @param fasta_db (Character) Path to a FASTA file. Mutually exclusive
#'   with `taxnames`.
#' @param taxnames (Character vector) Taxonomy header strings (without
#'   leading `>`). Mutually exclusive with `fasta_db`.
#' @param input_format (Character, default `"auto"`) Input taxonomy format.
#'   One of `"auto"`, `"sintax"`, `"unite"`, `"greengenes2"`.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path.
#'
#' @returns If `taxnames` is used, a character vector. If `fasta_db` is
#'   used, a `DNAStringSet` with reformatted names.
#' @export
#' @author Adrien Taudière
#' @seealso [format_fasta_db()], [format2sintax()], [format2dada2()]
#' @examples
#' # UNITE format → dada2_species
#' format2dada2_species(
#'   taxnames = "AB123;k__Fungi;g__Aspergillus;s__fumigatus"
#' )
#'
#' # SINTAX format → dada2_species
#' format2dada2_species(
#'   taxnames = "AB123;tax=k:Fungi,g:Aspergillus,s:fumigatus",
#'   input_format = "sintax"
#' )
format2dada2_species <- function(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL
) {
  format_fasta_db(
    fasta_db = fasta_db,
    taxnames = taxnames,
    output_format = "dada2_species",
    input_format = input_format,
    output_path = output_path
  )
}
