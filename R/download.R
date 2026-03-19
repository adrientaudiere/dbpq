# ——————————————————————————————————————————————————————————————————————
# Internal download helper
# ——————————————————————————————————————————————————————————————————————

#' Download a file with progress and validation
#'
#' @param url The URL to download from.
#' @param dest_path The local file path to save to.
#' @param verbose Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @keywords internal
download_file <- function(url, dest_path, verbose = TRUE) {
  if (verbose) {
    message("Downloading from:\n  ", url)
    message("Saving to:\n  ", dest_path)
  }

  tryCatch(
    {
      utils::download.file(
        url,
        destfile = dest_path,
        mode = "wb",
        quiet = !verbose
      )
    },
    error = function(e) {
      if (file.exists(dest_path)) {
        unlink(dest_path)
      }
      stop(
        "Download failed. Check your internet connection and that the URL ",
        "is still valid:\n  ",
        url,
        "\nOriginal error: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  if (!file.exists(dest_path) || file.size(dest_path) == 0) {
    if (file.exists(dest_path)) {
      unlink(dest_path)
    }
    stop(
      "Download produced an empty file. The URL may be invalid:\n  ",
      url,
      call. = FALSE
    )
  }

  if (verbose) {
    size_mb <- round(file.size(dest_path) / 1024^2, 1)
    message("Download complete (", size_mb, " MB)")
  }

  invisible(dest_path)
}


# ——————————————————————————————————————————————————————————————————————
# UNITE
# ——————————————————————————————————————————————————————————————————————

#' Download a UNITE reference database
#'
#' @description
#' Downloads the UNITE fungal ITS database for taxonomic assignment from
#' the UNITE DOI repository (PlutoF/Zenodo). Provides both "dynamic"
#' (including singletons) and "static" versions, for fungi or all eukaryotes.
#'
#' UNITE general FASTA releases use the `k__`/`p__` taxonomy format and
#' are compatible with dada2, VSEARCH, and other classifiers after
#' reformatting with [format2dada2()] or [format2sintax()].
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param type (Character, default `"dynamic"`) One of `"dynamic"` or
#'   `"static"`. Dynamic files include singletons.
#' @param taxon_group (Character, default `"fungi"`) One of `"fungi"` or
#'   `"eukaryotes"`.
#' @param version (Character, default `"10.0"`) UNITE version. Use `"10.0"`
#'   for the 2024 release.
#' @param doi (Character) If provided, overrides version-based URL
#'   construction with a direct DOI download. Useful for older or
#'   alternative releases.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' Since UNITE v10.0, the `.tgz` archive contains all clustering
#' variants (dynamic, 97%, 99%) bundled together. After downloading,
#' extract the archive and select the appropriate FASTA file.
#'
#' The S3 download URLs use opaque UUIDs that change between releases.
#' If the automatic URL fails, visit
#' <https://unite.ut.ee/repository.php> to find the current DOI and pass
#' it via the `doi` parameter, or download manually.
#'
#' Please cite UNITE: Abarenkov K et al. (2024) UNITE general FASTA
#' release for Fungi. UNITE Community.
#' \doi{10.15156/BIO/2959336}
#' @seealso [format2dada2()], [format2sintax()]
#' @examples
#' \dontrun{
#' # Download UNITE v10.0 dynamic for fungi
#' download_unite_db(dest_dir = "databases")
#'
#' # Download for all eukaryotes
#' download_unite_db(dest_dir = "databases", taxon_group = "eukaryotes")
#' }
download_unite_db <- function(
  dest_dir = ".",
  type = c("dynamic", "static"),
  taxon_group = c("fungi", "eukaryotes"),
  version = "10.0",
  doi = NULL,
  verbose = TRUE
) {
  type <- match.arg(type)
  taxon_group <- match.arg(taxon_group)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (!is.null(doi)) {
    # User-provided DOI: resolve to download URL
    url <- paste0("https://doi.org/", sub("^https?://doi.org/", "", doi))
    dest_file <- file.path(
      dest_dir,
      paste0("UNITE_", type, "_", taxon_group, ".tgz")
    )
    message(
      "Using user-provided DOI. You may need to follow redirects manually.\n",
      "Consider downloading from https://unite.ut.ee/repository.php"
    )
    download_file(url, dest_file, verbose = verbose)
    return(invisible(dest_file))
  }

  # Known S3 download URLs for UNITE v10.0 general FASTA release

  # Source: nf-core/ampliseq ref_databases.config
  # The .tgz archives contain dynamic, 97%, and 99% clustering variants
  # Note: S3 UUIDs are opaque and change between releases
  unite_urls <- list(
    fungi = list(
      dynamic = paste0(
        "https://s3.hpc.ut.ee/plutof-public/original/",
        "d18aa648-3f4c-4f46-84d4-c8c5d48439ba.tgz"
      ),
      static = paste0(
        "https://s3.hpc.ut.ee/plutof-public/original/",
        "d18aa648-3f4c-4f46-84d4-c8c5d48439ba.tgz"
      )
    ),
    eukaryotes = list(
      dynamic = paste0(
        "https://s3.hpc.ut.ee/plutof-public/original/",
        "1dda2021-4893-4f2f-b50e-87bfea795267.tgz"
      ),
      static = paste0(
        "https://s3.hpc.ut.ee/plutof-public/original/",
        "1dda2021-4893-4f2f-b50e-87bfea795267.tgz"
      )
    )
  )

  url <- unite_urls[[taxon_group]][[type]]

  if (is.null(url)) {
    stop(
      "No known download URL for UNITE version ",
      version,
      " (",
      type,
      ", ",
      taxon_group,
      ").\n",
      "Visit https://unite.ut.ee/repository.php for manual download.",
      call. = FALSE
    )
  }

  dest_file <- file.path(
    dest_dir,
    paste0(
      "sh_general_release_",
      type,
      "_",
      ifelse(taxon_group == "fungi", "s_", "s_all_"),
      gsub("\\.", "", version),
      ".tgz"
    )
  )

  download_file(url, dest_file, verbose = verbose)

  if (verbose) {
    message(
      "UNITE database saved as: ",
      dest_file,
      "\n",
      "Extract with: untar('",
      dest_file,
      "', exdir = '",
      dest_dir,
      "')"
    )
  }

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# SILVA
# ——————————————————————————————————————————————————————————————————————

#' Download a SILVA reference database
#'
#' @description
#' Downloads the SILVA ribosomal RNA database (16S/18S). By default,
#' downloads the dada2-formatted training sets from Zenodo (maintained by
#' Benjamin Callahan). Alternatively, downloads raw SILVA exports from
#' arb-silva.de.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character, default `"138.2"`) SILVA version number.
#' @param target (Character, default `"SSU"`) One of `"SSU"` or `"LSU"`.
#' @param format (Character, default `"dada2"`) One of:
#'   - `"dada2"`: dada2-formatted training set from Zenodo (NR99,
#'     recommended for `dada2::assignTaxonomy()`).
#'   - `"dada2_species"`: species assignment file for
#'     `dada2::addSpecies()`.
#'   - `"raw"`: raw SILVA NR99 FASTA with taxonomy from arb-silva.de.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' The dada2-formatted files are maintained by Benjamin Callahan on Zenodo
#' and are the recommended format for `dada2::assignTaxonomy()` and
#' `dada2::addSpecies()`. See
#' <https://benjjneb.github.io/dada2/training.html> for details.
#'
#' SILVA data is free for academic use. Commercial use requires a license.
#' See <https://www.arb-silva.de/silva-license-information/>.
#'
#' Please cite: Quast C et al. (2013) The SILVA ribosomal RNA gene
#' database project. Nucleic Acids Research 41:D590-D596.
#' \doi{10.1093/nar/gks1219}
#' @seealso [format2dada2()], [format2sintax()]
#' @examples
#' \dontrun{
#' # Download dada2-formatted SILVA for assignTaxonomy()
#' download_silva_db(dest_dir = "databases")
#'
#' # Download species assignment file
#' download_silva_db(dest_dir = "databases", format = "dada2_species")
#'
#' # Download raw SILVA NR99 FASTA
#' download_silva_db(dest_dir = "databases", format = "raw")
#' }
download_silva_db <- function(
  dest_dir = ".",
  version = "138.2",
  target = c("SSU", "LSU"),
  format = c("dada2", "dada2_species", "raw"),
  verbose = TRUE
) {
  target <- match.arg(target)
  format <- match.arg(format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # Zenodo record IDs for dada2-formatted SILVA
  zenodo_records <- list(
    "138.2" = "14169026",
    "138.1" = "4587955"
  )

  # Version string for URLs (138.2 -> 138_2 for arb-silva paths)
  version_us <- gsub("\\.", "_", version)

  if (format %in% c("dada2", "dada2_species")) {
    if (target == "LSU") {
      stop(
        "dada2-formatted files are only available for SSU. ",
        "Use format = 'raw' for LSU downloads.",
        call. = FALSE
      )
    }

    record_id <- zenodo_records[[version]]
    if (is.null(record_id)) {
      stop(
        "No known Zenodo record for SILVA v",
        version,
        ". ",
        "Known versions: ",
        paste(names(zenodo_records), collapse = ", "),
        ". Visit https://benjjneb.github.io/dada2/training.html",
        call. = FALSE
      )
    }

    if (format == "dada2") {
      filename <- paste0("silva_nr99_v", version, "_toSpecies_trainset.fa.gz")
    } else {
      filename <- paste0("silva_v", version, "_assignSpecies.fa.gz")
    }

    url <- paste0(
      "https://zenodo.org/records/",
      record_id,
      "/files/",
      filename
    )
  } else {
    # Raw SILVA export from arb-silva.de
    target_full <- paste0(target, "Ref_NR99")
    filename <- paste0(
      "SILVA_",
      version,
      "_",
      target_full,
      "_tax_silva_trunc.fasta.gz"
    )
    url <- paste0(
      "https://www.arb-silva.de/fileadmin/silva_databases/",
      "release_",
      version_us,
      "/Exports/",
      filename
    )
  }

  dest_file <- file.path(dest_dir, filename)
  download_file(url, dest_file, verbose = verbose)

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# PR2
# ——————————————————————————————————————————————————————————————————————

#' Download a PR2 reference database
#'
#' @description
#' Downloads the PR2 protist ribosomal reference database from GitHub
#' releases. PR2 provides 18S rRNA gene sequences for protists and other
#' eukaryotes.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character) PR2 version number (e.g., `"5.0.0"`). If
#'   `NULL` (default), the latest release is fetched from GitHub.
#' @param format (Character, default `"dada2"`) One of `"dada2"`, `"mothur"`,
#'   or `"UTAX"`.
#' @param marker (Character, default `"SSU"`) One of `"SSU"` or `"plastid"`.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' PR2 releases are hosted on GitHub at
#' <https://github.com/pr2database/pr2database/releases>.
#'
#' Please cite: Guillou L et al. (2013) The Protist Ribosomal Reference
#' database (PR2). Nucleic Acids Research 41:D1108-D1113.
#' \doi{10.1093/nar/gks1160}
#' @seealso [format2dada2()], [format2sintax()]
#' @examples
#' \dontrun{
#' # Download latest PR2 in dada2 format
#' download_pr2_db(dest_dir = "databases")
#'
#' # Download specific version in UTAX format
#' download_pr2_db(dest_dir = "databases", version = "5.0.0", format = "UTAX")
#' }
download_pr2_db <- function(
  dest_dir = ".",
  version = NULL,
  format = c("dada2", "mothur", "UTAX"),
  marker = c("SSU", "plastid"),
  verbose = TRUE
) {
  format <- match.arg(format)
  marker <- match.arg(marker)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # Get latest version from GitHub API if not specified
  if (is.null(version)) {
    if (verbose) {
      message("Querying GitHub for latest PR2 release...")
    }
    api_url <- paste0(
      "https://api.github.com/repos/pr2database/pr2database/",
      "releases/latest"
    )
    response <- tryCatch(
      jsonlite::fromJSON(api_url),
      error = function(e) {
        stop(
          "Could not query GitHub API for latest PR2 version. ",
          "Specify version manually (e.g., version = '5.0.0').\n",
          "Error: ",
          conditionMessage(e),
          call. = FALSE
        )
      }
    )
    version <- sub("^v", "", response$tag_name)
    if (verbose) {
      message("Latest PR2 version: ", version)
    }
  }

  # Construct filename
  # Pattern: pr2_version_{VERSION}_SSU_dada2.fasta.gz
  marker_str <- ifelse(marker == "SSU", "SSU", "plastid_16S")
  filename <- paste0(
    "pr2_version_",
    version,
    "_",
    marker_str,
    "_",
    format,
    ".fasta.gz"
  )

  url <- paste0(
    "https://github.com/pr2database/pr2database/releases/download/",
    "v",
    version,
    "/",
    filename
  )

  dest_file <- file.path(dest_dir, filename)
  download_file(url, dest_file, verbose = verbose)

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# BOLD
# ——————————————————————————————————————————————————————————————————————

#' Download sequences from BOLD Systems
#'
#' @description
#' Downloads reference sequences from BOLD Systems (Barcode of Life Data)
#' for a given taxonomic group. Unlike other databases, BOLD does not
#' provide a single pre-built reference FASTA — sequences are queried by
#' taxon via the BOLD API.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param taxon (Character, required) Taxonomic name to query (e.g.,
#'   `"Fungi"`, `"Arthropoda"`, `"Mammalia"`).
#' @param marker (Character, default `"COI-5P"`) The barcode marker. Common
#'   values: `"COI-5P"`, `"ITS"`, `"matK"`, `"rbcL"`.
#' @param output_format (Character, default `"fasta"`) Output format.
#'   Currently only `"fasta"` is supported.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' This function uses the BOLD v3 public API. For very large taxonomic
#' groups, the download may take a long time or fail due to server limits.
#' In such cases, consider using narrower taxonomic queries or the
#' [bold](https://docs.ropensci.org/bold/) R package.
#'
#' Please cite: Ratnasingham S & Hebert PDN (2007) BOLD: The Barcode of
#' Life Data System. Molecular Ecology Notes 7:355-364.
#' \doi{10.1111/j.1471-8286.2007.01678.x}
#' @examples
#' \dontrun{
#' # Download COI sequences for Fungi
#' download_bold_db(dest_dir = "databases", taxon = "Fungi")
#'
#' # Download ITS sequences for a specific order
#' download_bold_db(
#'   dest_dir = "databases",
#'   taxon = "Agaricales",
#'   marker = "ITS"
#' )
#' }
download_bold_db <- function(
  dest_dir = ".",
  taxon = NULL,
  marker = "COI-5P",
  output_format = "fasta",
  verbose = TRUE
) {
  if (is.null(taxon)) {
    stop("You must specify a taxon (e.g., taxon = 'Fungi').", call. = FALSE)
  }

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # BOLD v3 API for sequence downloads
  url <- paste0(
    "http://v3.boldsystems.org/index.php/API_Public/sequence",
    "?taxon=",
    utils::URLencode(taxon, reserved = TRUE)
  )

  filename <- paste0(
    "BOLD_",
    gsub(" ", "_", taxon),
    "_",
    marker,
    ".fasta"
  )
  dest_file <- file.path(dest_dir, filename)

  if (verbose) {
    message(
      "Querying BOLD API for '",
      taxon,
      "' sequences...\n",
      "Note: large taxonomic groups may take several minutes."
    )
  }

  download_file(url, dest_file, verbose = verbose)

  # The BOLD API returns all markers; filter by marker if needed
  if (verbose) {
    n_seq <- count_pattern_db(dest_file, pattern = ">")
    message("Downloaded ", n_seq, " sequences for '", taxon, "'")
    message(
      "Note: BOLD API returns all markers. You may want to filter ",
      "for '",
      marker,
      "' using filter_db()."
    )
  }

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# MaarjAM
# ——————————————————————————————————————————————————————————————————————

#' Download the MaarjAM reference database
#'
#' @description
#' Downloads the MaarjAM database of arbuscular mycorrhizal fungi (AMF)
#' virtual taxa (VT) sequences (18S rDNA). The database is maintained at
#' the University of Tartu.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param url (Character) Direct download URL for the MaarjAM FASTA file.
#'   Defaults to the known download endpoint. Override if the URL has
#'   changed.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' MaarjAM does not have a versioned API. The download URL may change.
#' If the default URL fails, visit <https://maarjam.ut.ee/?action=bDownload>
#' to find the current download link and pass it via the `url` parameter.
#'
#' Please cite: Opik M et al. (2010) The online database MaarjAM reveals
#' global and ecosystemic distribution patterns in arbuscular mycorrhizal
#' fungi (Glomeromycota). New Phytologist 188:223-241.
#' \doi{10.1111/j.1469-8137.2010.03334.x}
#' @examples
#' \dontrun{
#' download_marjaam_db(dest_dir = "databases")
#' }
download_marjaam_db <- function(
  dest_dir = ".",
  url = "https://maarjam.ut.ee/resources/maarjam_database.fasta",
  verbose = TRUE
) {
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  filename <- "maarjam_database.fasta"
  dest_file <- file.path(dest_dir, filename)

  tryCatch(
    download_file(url, dest_file, verbose = verbose),
    error = function(e) {
      stop(
        "MaarjAM download failed. The URL may have changed.\n",
        "Visit https://maarjam.ut.ee/?action=bDownload to find the ",
        "current download link, then use:\n",
        "  download_marjaam_db(url = 'https://...')\n",
        "Original error: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# Eukaryome
# ——————————————————————————————————————————————————————————————————————

#' Download the Eukaryome reference database
#'
#' @description
#' Downloads the Eukaryome database for eukaryotic organisms. Supports
#' multiple markers (SSU 18S, ITS, LSU 28S) and output formats (general
#' FASTA, dada2, mothur).
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param url (Character) Direct download URL for the Eukaryome file.
#'   Override if the URL has changed. If `NULL` (default), the function
#'   directs you to the Eukaryome download page.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly), or a message
#'   with download instructions if no URL is provided.
#' @export
#' @author Adrien Taudière
#' @details
#' Eukaryome does not provide a stable programmatic download API. Files
#' are available at <https://eukaryome.org/download/> in several formats:
#'
#' - General FASTA: <https://eukaryome.org/generalfasta/>
#' - dada2 format: <https://eukaryome.org/dada2/>
#' - mothur format: <https://eukaryome.org/mothur/>
#' - QIIME2 format: <https://eukaryome.org/qiime2/>
#'
#' Visit one of these pages, copy the direct download link, and pass it
#' via the `url` parameter.
#'
#' Please cite: Vasar M et al. (2024) Eukaryome: the rRNA gene reference
#' database for identification of all eukaryotes. Database.
#' \doi{10.1093/database/baae043}
#' @examples
#' \dontrun{
#' # Download with a specific URL from the Eukaryome website
#' download_eukaryome_db(
#'   dest_dir = "databases",
#'   url = "https://eukaryome.org/files/eukaryome_v1.9_SSU_dada2.fasta.gz"
#' )
#' }
download_eukaryome_db <- function(
  dest_dir = ".",
  url = NULL,
  verbose = TRUE
) {
  if (is.null(url)) {
    message(
      "Eukaryome does not provide stable programmatic download URLs.\n",
      "Please visit one of these pages to get the download link:\n",
      "  - General FASTA: https://eukaryome.org/generalfasta/\n",
      "  - dada2 format:  https://eukaryome.org/dada2/\n",
      "  - mothur format: https://eukaryome.org/mothur/\n",
      "  - QIIME2 format: https://eukaryome.org/qiime2/\n\n",
      "Then call:\n",
      "  download_eukaryome_db(url = 'https://...')"
    )
    return(invisible(NULL))
  }

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  filename <- basename(url)
  dest_file <- file.path(dest_dir, filename)

  download_file(url, dest_file, verbose = verbose)

  invisible(dest_file)
}
