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
  } else if (format == "dada2") {
    # Positional, prefix-less, no sequence ID (dada2 assignTaxonomy trainset).
    # Ranks are assigned by position; SILVA's first level is a domain (d:).
    parts <- strsplit(sub(";$", "", h), ";", fixed = TRUE)[[1]]
    keys <- c("d", "p", "c", "o", "f", "g", "s")[seq_along(parts)]
    ranks <- stats::setNames(parts, keys)
    list(id = NA_character_, ranks = ranks)
  } else {
    stop(
      "Unsupported input format: '",
      format,
      "'. ",
      "Use one of: 'sintax', 'unite', 'greengenes2', 'dada2'."
    )
  }
}


# Render a parsed header (list with id + ranks) to the target format string
# (without leading ">").
.render_tax_header <- function(parsed, format) {
  id <- parsed$id
  ranks <- parsed$ranks
  # For label-carrying formats, missing (NA) ranks are simply omitted; the
  # rank key preserves meaning. For positional dada2 they must be kept as
  # empty fields so ranks below an internal gap stay correctly aligned.
  ranks_present <- ranks[!is.na(ranks)]

  if (format == "sintax") {
    if (length(ranks_present) == 0L) {
      return(id)
    }
    rank_str <- paste(
      paste0(names(ranks_present), ":", ranks_present),
      collapse = ","
    )
    paste0(id, ";tax=", rank_str)
  } else if (format == "unite") {
    if (length(ranks_present) == 0L) {
      return(id)
    }
    rank_str <- paste(
      paste0(names(ranks_present), "__", ranks_present),
      collapse = ";"
    )
    paste0(id, ";", rank_str)
  } else if (format == "greengenes2") {
    if (length(ranks_present) == 0L) {
      return(id)
    }
    rank_str <- paste(
      paste0(names(ranks_present), "__", ranks_present),
      collapse = ";"
    )
    paste0(id, " ", rank_str)
  } else if (format == "dada2") {
    # Unprefixed semicolon-separated taxonomy, trailing semicolon, no ID.
    # Internal gaps (NA) become empty fields to keep ranks aligned.
    if (length(ranks) == 0L) {
      return(paste0(id, ";"))
    }
    ranks[is.na(ranks)] <- ""
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


# Assign synthetic sequential IDs to parsed records that lack one (e.g. dada2
# input, which is taxonomy-only). Zero-padded width adapts to record count.
.inject_ids <- function(parsed, id_prefix) {
  missing_id <- vapply(
    parsed,
    function(p) {
      is.na(p$id) || !nzchar(p$id)
    },
    logical(1)
  )
  if (any(missing_id)) {
    n <- sum(missing_id)
    w <- max(6L, nchar(n))
    ids <- paste0(id_prefix, formatC(seq_len(n), width = w, flag = "0"))
    parsed[missing_id] <- Map(
      function(p, i) {
        p$id <- i
        p
      },
      parsed[missing_id],
      ids
    )
  }
  parsed
}


# ——————————————————————————————————————————————————————————————————————
# Internal: build taxonomy headers from a sidecar lineage source
#
# Several databases ship sequences with accession-only FASTA headers and
# their taxonomy in a separate file (LTPlus CSV, KSGP .tax) or encoded in a
# non-standard header (BOLD, MaarjAM). These helpers turn a per-sequence
# lineage into the parsed (id + ranks) representation used by
# .render_tax_header(), so any download function can emit dada2 / sintax
# headers via the same renderer.
# ——————————————————————————————————————————————————————————————————————

# Rank keys used positionally for dada2 / sintax output.
.rank_keys <- c("d", "p", "c", "o", "f", "g", "s")

# Tokens that mean "no name at this rank" and should be treated as missing.
.is_missing_tax <- function(x) {
  is.na(x) |
    !nzchar(x) |
    grepl(
      "^(noname|unknown|unclassified|unidentified|incertae[ _]?sedis|na)$",
      x,
      ignore.case = TRUE
    )
}

# Map a rank-prefix letter to its rank key (kingdom and domain both -> "d").
.prefix_to_key <- c(
  d = "d",
  k = "d",
  p = "p",
  c = "c",
  o = "o",
  f = "f",
  g = "g",
  s = "s"
)

# Split a lineage string into a named ranks vector keyed d,p,c,o,f,g,s.
#
# Ranks are assigned sequentially by position, EXCEPT a token carrying an
# explicit rank prefix (`f__Name`, `o:Name`) is placed at that rank and resets
# the running position — this keeps later ranks aligned when an intermediate
# rank is missing (e.g. "Bacteria/.../noname~305/f__Ferroviaceae"). Missing
# tokens ("noname", "", "unclassified", …) become NA at their position so
# downstream ranks stay positionally aligned; trailing NA ranks are dropped.
# An internal-node suffix like "~427" is stripped from every token.
.lineage_to_ranks <- function(lineage, sep = "/") {
  if (length(lineage) != 1L || is.na(lineage) || !nzchar(trimws(lineage))) {
    return(character(0))
  }
  tokens <- strsplit(lineage, sep, fixed = TRUE)[[1]]
  ranks <- stats::setNames(rep(NA_character_, length(.rank_keys)), .rank_keys)
  idx <- 1L
  for (tok in tokens) {
    tok <- trimws(tok)
    pm <- regmatches(tok, regexec("^([a-zA-Z])(?:__|:)(.*)$", tok))[[1]]
    if (length(pm) == 3L && tolower(pm[[2]]) %in% names(.prefix_to_key)) {
      key <- .prefix_to_key[[tolower(pm[[2]])]]
      name <- pm[[3]]
      idx <- match(key, .rank_keys) + 1L
    } else {
      if (idx > length(.rank_keys)) {
        break
      }
      key <- .rank_keys[[idx]]
      name <- tok
      idx <- idx + 1L
    }
    name <- sub("~\\d+$", "", name)
    if (!.is_missing_tax(name)) {
      ranks[[key]] <- name
    }
  }
  last <- suppressWarnings(max(which(!is.na(ranks))))
  if (!is.finite(last)) {
    return(character(0))
  }
  ranks[seq_len(last)]
}

# Write a taxonomy-headed FASTA from a FASTA file plus an id -> ranks map.
#
# Streams the FASTA line by line (so multi-GB references such as KSGP do not
# need to be loaded into memory) and looks up taxonomy through a hashed
# environment (O(1) per header, not a linear scan of the id list). Only the
# header lines are rewritten; sequence content is copied verbatim.
#
# @param fasta_path Path to the source FASTA (plain or gzipped).
# @param id2ranks Named list: names are sequence IDs (first whitespace-
#   delimited token of the FASTA header), values are ranks vectors as
#   returned by .lineage_to_ranks().
# @param tax_format "dada2" or "sintax".
# @param output_path Where to write the reformatted FASTA (.gz honoured).
#   May equal fasta_path (written via a temporary file, then renamed).
# @param verbose Print a summary of how many sequences were annotated.
# @return output_path (invisibly).
.write_tax_fasta <- function(
  fasta_path,
  id2ranks,
  tax_format = c("dada2", "sintax"),
  output_path,
  verbose = TRUE
) {
  tax_format <- match.arg(tax_format)

  # Hashed lookup: list `[[` on character names is a linear scan, far too slow
  # for hundreds of thousands of sequences.
  lookup <- new.env(hash = TRUE, parent = emptyenv())
  nm <- names(id2ranks)
  for (i in seq_along(id2ranks)) {
    if (is.na(nm[[i]]) || !nzchar(nm[[i]])) {
      next
    }
    assign(nm[[i]], id2ranks[[i]], envir = lookup)
  }

  is_gz <- function(p) grepl("\\.gz$", p, ignore.case = TRUE)
  incon <- if (is_gz(fasta_path)) {
    gzfile(fasta_path, "rt")
  } else {
    file(fasta_path, "rt")
  }
  tmp_out <- tempfile(tmpdir = dirname(output_path), fileext = ".fa")
  outcon <- if (is_gz(output_path)) {
    gzfile(tmp_out, "wt")
  } else {
    file(tmp_out, "wt")
  }
  on.exit(
    {
      try(close(incon), silent = TRUE)
      try(close(outcon), silent = TRUE)
    },
    add = TRUE
  )

  n_seq <- 0L
  n_no_tax <- 0L
  repeat {
    lines <- readLines(incon, n = 20000L)
    if (length(lines) == 0L) {
      break
    }
    hdr <- startsWith(lines, ">")
    if (any(hdr)) {
      ids <- sub("\\s.*$", "", sub("^>", "", lines[hdr]))
      lines[hdr] <- vapply(
        ids,
        function(id) {
          ranks <- if (exists(id, envir = lookup, inherits = FALSE)) {
            get(id, envir = lookup, inherits = FALSE)
          } else {
            n_no_tax <<- n_no_tax + 1L
            character(0)
          }
          paste0(
            ">",
            .render_tax_header(list(id = id, ranks = ranks), tax_format)
          )
        },
        character(1),
        USE.NAMES = FALSE
      )
      n_seq <- n_seq + length(ids)
    }
    writeLines(lines, outcon)
  }
  close(incon)
  close(outcon)
  file.rename(tmp_out, output_path)

  if (verbose) {
    message(
      "Wrote ",
      tax_format,
      " taxonomy FASTA: ",
      output_path,
      " (",
      n_seq,
      " sequences",
      if (n_no_tax > 0) paste0(", ", n_no_tax, " without taxonomy") else "",
      ")"
    )
  }

  invisible(output_path)
}


# Rewrite a FASTA whose taxonomy is already IN the header (e.g. Greengenes2
# `>d__Bacteria;p__...;g__...;`) to dada2 / sintax. Streams line by line.
# `header_sep` is the rank separator inside the header (";" for GG2). For
# sintax output, sequences that carry no ID get a synthetic `id_prefix` ID.
.reformat_inheader_fasta <- function(
  fasta_path,
  header_sep,
  tax_format = c("dada2", "sintax"),
  output_path,
  id_prefix = "seq",
  verbose = TRUE
) {
  tax_format <- match.arg(tax_format)
  is_gz <- function(p) grepl("\\.gz$", p, ignore.case = TRUE)
  incon <- if (is_gz(fasta_path)) {
    gzfile(fasta_path, "rt")
  } else {
    file(fasta_path, "rt")
  }
  tmp_out <- tempfile(tmpdir = dirname(output_path), fileext = ".fa")
  outcon <- if (is_gz(output_path)) {
    gzfile(tmp_out, "wt")
  } else {
    file(tmp_out, "wt")
  }
  on.exit(
    {
      try(close(incon), silent = TRUE)
      try(close(outcon), silent = TRUE)
    },
    add = TRUE
  )

  counter <- 0L
  n_seq <- 0L
  repeat {
    lines <- readLines(incon, n = 20000L)
    if (length(lines) == 0L) {
      break
    }
    hdr <- startsWith(lines, ">")
    if (any(hdr)) {
      lines[hdr] <- vapply(
        sub("^>", "", lines[hdr]),
        function(h) {
          counter <<- counter + 1L
          ranks <- .lineage_to_ranks(h, sep = header_sep)
          id <- paste0(id_prefix, formatC(counter, width = 8L, flag = "0"))
          paste0(
            ">",
            .render_tax_header(list(id = id, ranks = ranks), tax_format)
          )
        },
        character(1),
        USE.NAMES = FALSE
      )
      n_seq <- n_seq + sum(hdr)
    }
    writeLines(lines, outcon)
  }
  close(incon)
  close(outcon)
  file.rename(tmp_out, output_path)
  if (verbose) {
    message(
      "Wrote ",
      tax_format,
      " taxonomy FASTA: ",
      output_path,
      " (",
      n_seq,
      " sequences)"
    )
  }
  invisible(output_path)
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
#'   `"unite"`, `"greengenes2"`, `"dada2"`. The positional `"dada2"` input
#'   (taxonomy-only headers, no sequence ID) is assigned ranks by position
#'   (`d,p,c,o,f,g,s`); see `id_prefix` for the generated labels.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path and return the `DNAStringSet`
#'   invisibly.
#' @param id_prefix (Character, default `"seq"`) Prefix used to build
#'   synthetic sequential sequence IDs (e.g. `"seq000001"`) for input
#'   formats that carry no per-sequence identifier (`"dada2"`). Ignored when
#'   the input already provides IDs.
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
  output_path = NULL,
  id_prefix = "seq"
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
    parsed <- .inject_ids(parsed, id_prefix)
    vapply(
      parsed,
      function(p) {
        .render_tax_header(p, output_format)
      },
      character(1)
    )
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
    parsed <- .inject_ids(parsed, id_prefix)
    new_names <- vapply(
      parsed,
      function(p) {
        .render_tax_header(p, output_format)
      },
      character(1)
    )
    names(dna) <- new_names
    if (!is.null(output_path)) {
      # writeXStringSet() writes plain text unless compress = TRUE, so honour a
      # .gz output path and actually gzip the file.
      Biostrings::writeXStringSet(
        dna,
        filepath = output_path,
        compress = grepl("\\.gz$", output_path, ignore.case = TRUE)
      )
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
#'   One of `"auto"`, `"unite"`, `"greengenes2"`, `"dada2"`.
#' @param output_path (Character) If provided and `fasta_db` is used, write
#'   the reformatted FASTA to this path.
#' @param id_prefix (Character, default `"seq"`) Prefix for synthetic
#'   sequence IDs generated when the input has none (e.g. `"dada2"`).
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
#'
#' # dada2 trainset (taxonomy-only, positional) → SINTAX with synthetic IDs
#' format2sintax(
#'   taxnames = "Bacteria;Pseudomonadota;Gammaproteobacteria;Vibrio;",
#'   input_format = "dada2",
#'   id_prefix = "SILVA_"
#' )
format2sintax <- function(
  fasta_db = NULL,
  taxnames = NULL,
  input_format = "auto",
  output_path = NULL,
  id_prefix = "seq"
) {
  format_fasta_db(
    fasta_db = fasta_db,
    taxnames = taxnames,
    output_format = "sintax",
    input_format = input_format,
    output_path = output_path,
    id_prefix = id_prefix
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
