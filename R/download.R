# ——————————————————————————————————————————————————————————————————————
# Internal download helper
# ——————————————————————————————————————————————————————————————————————

#' Download a file with progress and validation
#'
#' @param url The URL to download from.
#' @param dest_path The local file path to save to.
#' @param verbose Print progress messages.
#' @param timeout (Numeric, default `Inf`) Timeout in seconds passed to
#'   [utils::download.file()] via `options(timeout = ...)` for the duration
#'   of the call. `Inf` disables the timeout, which is needed for multi-GB
#'   reference databases such as KSGP (>2 GB) and SILVA trainsets that
#'   take longer than R's 60-second default to download.
#'
#' @returns The path to the downloaded file (invisibly).
#' @keywords internal
download_file <- function(url, dest_path, verbose = TRUE, timeout = Inf) {
  if (verbose) {
    message("Downloading from:\n  ", url)
    message("Saving to:\n  ", dest_path)
  }

  # download.file() reads `options("timeout")`; set it for this call and
  # restore the prior value afterwards so we don't leak into the caller's
  # session.
  old_timeout <- getOption("timeout")
  if (!is.finite(timeout) || timeout != old_timeout) {
    options(timeout = timeout)
    on.exit(options(timeout = old_timeout), add = TRUE)
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
#'   `"static"`. Dynamic files include singletons. Only used when
#'   `taxonomic_format = "default"`. Note: as of UNITE v10.0, separate
#'   static/dynamic archives are not available for `taxon_group = "fungi"`;
#'   both options download the same archive.
#' @param taxon_group (Character, default `"fungi"`) One of `"fungi"` or
#'   `"eukaryotes"`.
#' @param version (Character, default `"10.0"`) UNITE version. Use `"10.0"`
#'   for the 2024 release.
#' @param taxonomic_format (Character, default `"default"`) One of
#'   `"default"` or `"sintax"`. When `"default"`, downloads the general
#'   FASTA release (`.tgz` archive with `k__`/`p__` taxonomy). When
#'   `"sintax"`, downloads a single FASTA file already formatted for
#'   VSEARCH SINTAX classification (with `tax=d:...` headers).
#' @param doi (Character) If provided, overrides version-based URL
#'   construction with a direct DOI download. Useful for older or
#'   alternative releases.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' When `taxonomic_format = "default"`: since UNITE v10.0, the `.tgz`
#' archive contains all clustering variants (dynamic, 97%, 99%) bundled
#' together. After downloading, extract the archive and select the
#' appropriate FASTA file.
#'
#' When `taxonomic_format = "sintax"`: the downloaded `.gz` file is a
#' single FASTA with SINTAX-ready taxonomy headers. This file can be used
#' directly with `vsearch --sintax`.
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
#' # Download UNITE v10.0 default (general FASTA archive) for fungi
#' download_unite_db(dest_dir = "databases")
#'
#' # Download UNITE v10.0 SINTAX-formatted for fungi
#' download_unite_db(dest_dir = "databases", taxonomic_format = "sintax")
#'
#' # Download for all eukaryotes in SINTAX format
#' download_unite_db(
#'   dest_dir = "databases",
#'   taxon_group = "eukaryotes",
#'   taxonomic_format = "sintax"
#' )
#' }
download_unite_db <- function(
  dest_dir = ".",
  type = c("dynamic", "static"),
  taxon_group = c("fungi", "eukaryotes"),
  version = "10.0",
  taxonomic_format = c("default", "sintax"),
  doi = NULL,
  verbose = TRUE
) {
  type <- match.arg(type)
  taxon_group <- match.arg(taxon_group)
  taxonomic_format <- match.arg(taxonomic_format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (!is.null(doi)) {
    # User-provided DOI: resolve to download URL
    url <- paste0("https://doi.org/", sub("^https?://doi.org/", "", doi))
    ext <- ifelse(taxonomic_format == "sintax", ".gz", ".tgz")
    dest_file <- file.path(
      dest_dir,
      paste0("UNITE_", type, "_", taxon_group, ext)
    )
    message(
      "Using user-provided DOI. You may need to follow redirects manually.\n",
      "Consider downloading from https://unite.ut.ee/repository.php"
    )
    download_file(url, dest_file, verbose = verbose)
    return(invisible(dest_file))
  }

  if (taxonomic_format == "sintax") {
    # Known S3 download URLs for UNITE v10.0 SINTAX FASTA release
    # Source: nf-core/ampliseq ref_databases.config (sintax_ref_taxonomy)
    # Note: S3 UUIDs are opaque and change between releases
    sintax_urls <- list(
      fungi = paste0(
        "https://s3.hpc.ut.ee/plutof-public/original/",
        "b27cffec-1e7d-4584-93d3-12add9fa180b.gz"
      ),
      eukaryotes = paste0(
        "https://s3.hpc.ut.ee/plutof-public/original/",
        "6f19ddb6-1ac0-4834-a74c-b639688878a4.gz"
      )
    )

    url <- sintax_urls[[taxon_group]]

    if (is.null(url)) {
      stop(
        "No known SINTAX download URL for UNITE version ",
        version,
        " (",
        taxon_group,
        ").\n",
        "Visit https://unite.ut.ee/repository.php for manual download.",
        call. = FALSE
      )
    }

    dest_file <- file.path(
      dest_dir,
      paste0(
        "sh_general_release_sintax_",
        ifelse(taxon_group == "fungi", "s_", "s_all_"),
        gsub("\\.", "", version),
        ".fasta.gz"
      )
    )

    download_file(url, dest_file, verbose = verbose)

    if (verbose) {
      message(
        "UNITE SINTAX database saved as: ",
        dest_file,
        "\n",
        "This file can be used directly with: ",
        "vsearch --sintax reads.fasta --db ",
        dest_file,
        " --tabbedout out.txt --sintax_cutoff 0.8"
      )
    }

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

  if (taxon_group == "fungi" && type == "static") {
    message(
      "Note: UNITE v10.0 does not ship separate static/dynamic archives for ",
      "fungi. Downloading the single available fungi archive."
    )
  }

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

#' Download a SILVA reference database NR99 version
#'
#' @description
#' Downloads the SILVA ribosomal RNA database (16S/18S/23S/28S). By default,
#' downloads the dada2-formatted training sets from the official arb-silva.de
#' DADA2 release (available for both SSU and LSU). Can also produce a
#' SINTAX-formatted database (converted locally from the dada2 trainset) or
#' download the raw SILVA NR99 export.
#'
#' For the PARC version (all sequences, not clustered like NR99), see
#' `dada2:::makeSpeciesFasta_Silva()` on the manually downloaded FASTA file.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character, default `"138.2"`) SILVA version number. Only
#'   the current SILVA release is hosted at the arb-silva DADA2 path used by
#'   the dada2/dada2_species/sintax formats.
#' @param target (Character, default `"SSU"`) One of `"SSU"` or `"LSU"`.
#' @param format (Character, default `"dada2"`) One of:
#'   - `"dada2"`: dada2-formatted `toSpecies` training set (NR99,
#'     recommended for `dada2::assignTaxonomy()`).
#'   - `"dada2_species"`: species assignment file for
#'     `dada2::addSpecies()`.
#'   - `"sintax"`: VSEARCH/USEARCH SINTAX database, converted locally from
#'     the dada2 `toSpecies` trainset (7 ranks `d,p,c,o,f,g,s`). Sequence
#'     labels are synthetic (`SILVA<version>_<target>_NNNNNN`) because the
#'     dada2 trainset carries no accession. Written as a separate
#'     `*_sintax.fasta.gz` file.
#'   - `"raw"`: raw SILVA NR99 FASTA with taxonomy from arb-silva.de.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the resulting file (invisibly). For `"sintax"` this
#'   is the converted `*_sintax.fasta.gz`; the intermediate trainset is also
#'   kept in `dest_dir`.
#' @export
#' @author Adrien Taudière
#' @details
#' The dada2-formatted files are provided by arb-silva.de and are the
#' recommended format for `dada2::assignTaxonomy()` and
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
#' # Download a SINTAX database for SSU (converted from the dada2 trainset)
#' download_silva_db(dest_dir = "databases", format = "sintax")
#'
#' # SINTAX database for LSU
#' download_silva_db(dest_dir = "databases", target = "LSU", format = "sintax")
#'
#' # Download raw SILVA NR99 FASTA
#' download_silva_db(dest_dir = "databases", format = "raw")
#' }
download_silva_db <- function(
  dest_dir = ".",
  version = "138.2",
  target = c("SSU", "LSU"),
  format = c("dada2", "dada2_species", "sintax", "raw"),
  verbose = TRUE
) {
  target <- match.arg(target)
  format <- match.arg(format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (format == "raw") {
    # Raw SILVA export from arb-silva.de (version dir uses 138.2 -> 138_2)
    version_us <- gsub("\\.", "_", version)
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
    dest_file <- file.path(dest_dir, filename)
    download_file(url, dest_file, verbose = verbose)
    return(invisible(dest_file))
  }

  # dada2-formatted training sets from the official arb-silva DADA2 release
  # (available for both SSU and LSU). The path segment is the DADA2 tooling
  # release; the filename carries the SILVA version.
  dada2_tool_version <- "1.36.0"
  dada2_base <- paste0(
    "https://www.arb-silva.de/fileadmin/silva_databases/current/DADA2/",
    dada2_tool_version,
    "/",
    target,
    "/"
  )

  if (format == "dada2_species") {
    filename <- paste0("silva_v", version, "_assignSpecies.fa.gz")
  } else {
    # "dada2" and "sintax" both start from the toSpecies trainset
    filename <- paste0("silva_nr99_v", version, "_toSpecies_trainset.fa.gz")
  }
  url <- paste0(dada2_base, filename)
  dest_file <- file.path(dest_dir, filename)
  download_file(url, dest_file, verbose = verbose)

  if (format == "sintax") {
    sintax_file <- file.path(
      dest_dir,
      paste0("silva_nr99_v", version, "_", target, "_sintax.fasta.gz")
    )
    if (verbose) {
      message("Converting dada2 trainset to SINTAX format ...")
    }
    format2sintax(
      fasta_db = dest_file,
      input_format = "dada2",
      output_path = sintax_file,
      id_prefix = paste0("SILVA", version, "_", target, "_")
    )
    return(invisible(sintax_file))
  }

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
#' For more advanced access to PR2 data (e.g., full taxonomy tables,
#' metadata, or custom queries), see the
#' [pr2database](https://pr2database.github.io/pr2database/) R package.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character) PR2 version number (e.g., `"5.0.0"`). If
#'   `NULL` (default), the latest release is fetched from GitHub.
#' @param format (Character, default `"dada2"`) One of `"dada2"`, `"mothur"`,
#'   `"UTAX"`, or `"sintax"` (alias for `"UTAX"`). See **Taxonomic ranks**
#'   below: the `"dada2"` file keeps PR2's 9 ranks, whereas the
#'   `"UTAX"`/`"sintax"` file collapses them to 8 (Division and Subdivision
#'   are merged).
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
#' ## Taxonomic ranks
#'
#' PR2 uses **9** taxonomic ranks. The `"dada2"` file keeps all nine as a
#' positional, semicolon-delimited lineage (no rank prefixes); pass them to
#' [dada2::assignTaxonomy()] (via [MiscMetabar::add_new_taxonomy_pq()] with
#' `method = "dada2"`) through `taxLevels`:
#'
#' `c("Domain", "Supergroup", "Division", "Subdivision", "Class", "Order",
#' "Family", "Genus", "Species")`
#'
#' The `"UTAX"`/`"sintax"` file targets VSEARCH/USEARCH SINTAX and uses the
#' **8** standard single-letter rank prefixes (`k, d, p, c, o, f, g, s`). To
#' fit PR2's nine ranks onto them, PR2 **merges Division and Subdivision**
#' into the `p:` rank (joined by `-`). The 9 → 8 mapping is:
#'
#' | PR2 rank (dada2)        | SINTAX prefix (UTAX)            |
#' | ----------------------- | ------------------------------ |
#' | Domain                  | `k:`                           |
#' | Supergroup              | `d:`                           |
#' | Division + Subdivision  | `p:` (e.g. `Alveolata-Dinoflagellata`) |
#' | Class                   | `c:`                           |
#' | Order                   | `o:`                           |
#' | Family                  | `f:`                           |
#' | Genus                   | `g:`                           |
#' | Species                 | `s:`                           |
#'
#' Mind the per-method argument when calling
#' [MiscMetabar::add_new_taxonomy_pq()]:
#' - `method = "dada2"` (the `"dada2"` download) keeps all 9 ranks — pass the
#'   9 names above as **`taxLevels`** (forwarded to [dada2::assignTaxonomy()]).
#' - `method = "sintax"` (the `"sintax"`/`"UTAX"` download) has 8 ranks — pass
#'   8 names as **`taxa_ranks`**, e.g. `c("Domain", "Supergroup",
#'   "Division_Subdivision", "Class", "Order", "Family", "Genus", "Species")`.
#'   The dada2 `taxLevels` argument is **ignored** by the SINTAX path, so the
#'   default 7 ranks would be used and parsing the 8-rank output fails.
#'
#' Please cite: Guillou L et al. (2013) The Protist Ribosomal Reference
#' database (PR2). Nucleic Acids Research 41:D1108-D1113.
#' \doi{10.1093/nar/gks1160}
#' @seealso [format2dada2()], [format2sintax()],
#'   [pr2database](https://pr2database.github.io/pr2database/) R package
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
  format = c("dada2", "mothur", "UTAX", "sintax"),
  marker = c("SSU", "plastid"),
  verbose = TRUE
) {
  format <- match.arg(format)
  # "sintax" is an alias for "UTAX" (same format, different naming conventions)
  if (format == "sintax") {
    format <- "UTAX"
  }
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
#' @param tax_format (Character, default `"dada2"`) Taxonomy format written
#'   into the FASTA headers, so the file can feed
#'   `MiscMetabar::add_new_taxonomy_pq()`. One of:
#'   - `"dada2"`: unprefixed, positional ranks
#'     (`>Phylum;Class;Order;Family;Genus;Species;`).
#'   - `"sintax"`: `>processid;tax=p:Phylum,c:Class,...`.
#'   - `"none"`: the raw BOLD sequence FASTA with `processid|taxon|marker`
#'     headers (no ranked taxonomy).
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' This function uses the BOLD public API hosted at `v3.boldsystems.org`,
#' which remains available after the main BOLD site's migration to v5. With
#' `tax_format = "none"` it queries the `sequence` endpoint (FASTA). With
#' `"dada2"`/`"sintax"` it queries the `combined` endpoint (TSV with the full
#' ranked taxonomy), keeps the requested `marker`, and writes a
#' taxonomy-headed FASTA (gaps removed). BOLD's taxonomy starts at phylum, so
#' the dada2 output has no kingdom level.
#'
#' For very large taxa the download may be slow or hit server limits; use
#' narrower queries, or the [BOLDconnectR](https://www.boldsystems.org/data/boldconnectr/)
#' package for the full v5 (BCDM) data model.
#'
#' Please cite: Ratnasingham S & Hebert PDN (2007) BOLD: The Barcode of
#' Life Data System. Molecular Ecology Notes 7:355-364.
#' \doi{10.1111/j.1471-8286.2007.01678.x}
#' @examples
#' \dontrun{
#' # COI reference for a genus, dada2 taxonomy headers
#' download_bold_db(dest_dir = "databases", taxon = "Danaus")
#'
#' # ITS sequences for an order, SINTAX headers
#' download_bold_db(
#'   dest_dir = "databases",
#'   taxon = "Agaricales",
#'   marker = "ITS",
#'   tax_format = "sintax"
#' )
#' }
download_bold_db <- function(
  dest_dir = ".",
  taxon = NULL,
  marker = "COI-5P",
  tax_format = c("dada2", "sintax", "none"),
  verbose = TRUE
) {
  if (is.null(taxon)) {
    stop("You must specify a taxon (e.g., taxon = 'Fungi').", call. = FALSE)
  }
  tax_format <- match.arg(tax_format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  dest_file <- file.path(
    dest_dir,
    paste0("BOLD_", gsub(" ", "_", taxon), "_", marker, ".fasta")
  )

  if (verbose) {
    message(
      "Querying BOLD for '",
      taxon,
      "'. Large taxonomic groups may take several minutes."
    )
  }

  # tax_format = "none": raw sequence FASTA (all markers; headers carry only
  # processid|taxon|marker).
  if (tax_format == "none") {
    url <- paste0(
      "https://v3.boldsystems.org/index.php/API_Public/sequence?taxon=",
      utils::URLencode(taxon, reserved = TRUE)
    )
    download_file(url, dest_file, verbose = verbose)
    return(invisible(dest_file))
  }

  # Otherwise pull the "combined" endpoint (specimen + sequence) which carries
  # the full ranked taxonomy, then write taxonomy-headed FASTA for `marker`.
  url <- paste0(
    "https://v3.boldsystems.org/index.php/API_Public/combined?format=tsv",
    "&taxon=",
    utils::URLencode(taxon, reserved = TRUE)
  )
  tsv <- tempfile(fileext = ".tsv")
  on.exit(unlink(tsv), add = TRUE)
  download_file(url, tsv, verbose = FALSE)

  d <- utils::read.table(
    tsv,
    sep = "\t",
    header = TRUE,
    quote = "",
    comment.char = "",
    fill = TRUE,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA")
  )
  if (!is.null(marker) && "markercode" %in% names(d)) {
    d <- d[!is.na(d$markercode) & d$markercode == marker, , drop = FALSE]
  }
  d <- d[!is.na(d$nucleotides) & nzchar(d$nucleotides), , drop = FALSE]
  if (nrow(d) == 0) {
    stop(
      "BOLD returned no '",
      marker,
      "' sequences for '",
      taxon,
      "'. Check the taxon/marker, or try tax_format = 'none'.",
      call. = FALSE
    )
  }

  rank_cols <- c(
    p = "phylum_name",
    c = "class_name",
    o = "order_name",
    f = "family_name",
    g = "genus_name",
    s = "species_name"
  )
  con <- file(dest_file, "w")
  on.exit(close(con), add = TRUE)
  for (i in seq_len(nrow(d))) {
    vals <- vapply(
      rank_cols,
      function(col) if (col %in% names(d)) as.character(d[[col]][i]) else NA,
      character(1)
    )
    vals[.is_missing_tax(vals)] <- NA_character_
    last <- suppressWarnings(max(which(!is.na(vals))))
    ranks <- if (is.finite(last)) {
      stats::setNames(vals[seq_len(last)], names(rank_cols)[seq_len(last)])
    } else {
      character(0)
    }
    header <- .render_tax_header(
      list(id = d$processid[i], ranks = ranks),
      tax_format
    )
    seq <- gsub("[-.]", "", d$nucleotides[i])
    writeLines(c(paste0(">", header), seq), con)
  }

  if (verbose) {
    message("Wrote ", nrow(d), " '", marker, "' sequences to ", dest_file)
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
#' virtual taxa (VT) sequences, maintained at the University of Tartu. The
#' QIIME-formatted release (a zip bundling a FASTA and a taxonomy table) is
#' used so that the resulting FASTA carries taxonomy in its headers, ready
#' for `MiscMetabar::add_new_taxonomy_pq()`.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param dataset (Character, default `"SSU"`) Which MaarjAM marker release
#'   to download. One of `"SSU"`, `"SSU_TYPE"`, `"LSU"`, `"full_ITS"`,
#'   `"onlyITS"`.
#' @param tax_format (Character, default `"dada2"`) Taxonomy format written
#'   into the FASTA headers. One of `"dada2"`, `"sintax"`, or `"none"` (keep
#'   the QIIME `accession_VTX...` headers without taxonomy).
#' @param url (Character) Direct download URL for the MaarjAM QIIME zip. If
#'   `NULL` (default), it is built from `dataset`. Override if the URL has
#'   changed.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded FASTA file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' The download links are listed at <https://maarjam.ut.ee/?action=bDownload>.
#' The QIIME zip contains `*.qiime.fasta` and `*.qiime.txt` (a tab-separated
#' `id  k__Fungi;p__...;s__VTX...` table); taxonomy is merged into the FASTA
#' headers by matching sequence IDs.
#'
#' Please cite: Opik M et al. (2010) The online database MaarjAM reveals
#' global and ecosystemic distribution patterns in arbuscular mycorrhizal
#' fungi (Glomeromycota). New Phytologist 188:223-241.
#' \doi{10.1111/j.1469-8137.2010.03334.x}
#' @examples
#' \dontrun{
#' # SSU (18S) AMF database with dada2 taxonomy headers
#' download_marjaam_db(dest_dir = "databases")
#'
#' # SINTAX-formatted headers
#' download_marjaam_db(dest_dir = "databases", tax_format = "sintax")
#' }
download_marjaam_db <- function(
  dest_dir = ".",
  dataset = c("SSU", "SSU_TYPE", "LSU", "full_ITS", "onlyITS"),
  tax_format = c("dada2", "sintax", "none"),
  url = NULL,
  verbose = TRUE
) {
  dataset <- match.arg(dataset)
  tax_format <- match.arg(tax_format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (is.null(url)) {
    url <- paste0(
      "https://maarjam.ut.ee/resources/maarjam_database_",
      dataset,
      ".qiime.2021.zip"
    )
  }

  zip_file <- tempfile(fileext = ".zip")
  exdir <- tempfile()
  on.exit(unlink(c(zip_file, exdir), recursive = TRUE), add = TRUE)
  download_file(url, zip_file, verbose = verbose)
  dir.create(exdir)
  utils::unzip(zip_file, exdir = exdir)

  fa <- list.files(
    exdir,
    pattern = "\\.fasta$",
    full.names = TRUE,
    recursive = TRUE
  )[1]
  if (is.na(fa)) {
    stop("No FASTA found in the MaarjAM archive: ", url, call. = FALSE)
  }
  dest_file <- file.path(dest_dir, paste0("maarjam_", dataset, ".fasta"))
  file.copy(fa, dest_file, overwrite = TRUE)

  if (tax_format != "none") {
    txt <- list.files(
      exdir,
      pattern = "\\.txt$",
      full.names = TRUE,
      recursive = TRUE
    )[1]
    if (is.na(txt)) {
      warning(
        "No taxonomy table found in the MaarjAM archive; headers left ",
        "unannotated.",
        call. = FALSE
      )
    } else {
      tax_tab <- utils::read.table(
        txt,
        sep = "\t",
        quote = "",
        comment.char = "",
        stringsAsFactors = FALSE,
        col.names = c("id", "tax")
      )
      id2ranks <- stats::setNames(
        lapply(tax_tab$tax, .lineage_to_ranks, sep = ";"),
        tax_tab$id
      )
      .write_tax_fasta(
        fasta_path = dest_file,
        id2ranks = id2ranks,
        tax_format = tax_format,
        output_path = dest_file,
        verbose = verbose
      )
    }
  }

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
#' - SINTAX format: <https://eukaryome.org/sintax/>
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
      "  - SINTAX format: https://eukaryome.org/sintax/\n",
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


# ——————————————————————————————————————————————————————————————————————
# Greengenes2
# ——————————————————————————————————————————————————————————————————————

#' Download a Greengenes2 reference database
#'
#' @description
#' Downloads the Greengenes2 16S rRNA database. By default, downloads the
#' dada2-formatted training sets from Zenodo (maintained by Benjamin
#' Callahan). Alternatively, downloads backbone sequences from the
#' Greengenes2 FTP server.
#'
#' Note that Greengenes2 uses `d__` (domain) instead of `k__` (kingdom)
#' as the first rank prefix. Use `tax_format = "greengenes2"` with
#' [summarize_db()] and [list_ranks_db()] for correct parsing.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param version (Character, default `"2024.09"`) Greengenes2 version
#'   in `YYYY.MM` format.
#' @param format (Character, default `"dada2"`) One of:
#'   - `"dada2"`: dada2-formatted training set from Zenodo (recommended
#'     for `dada2::assignTaxonomy()`).
#'   - `"dada2_species"`: species-level training set for
#'     `dada2::assignTaxonomy()` (includes species).
#'   - `"fasta"`: plain FASTA sequences from the FTP server.
#' @param tax_format (Character, default `"dada2"`) How to write taxonomy in
#'   the headers of the `"dada2"`/`"dada2_species"` training set. The
#'   Greengenes2 trainset ships with `d__`/`p__` rank prefixes, which
#'   `dada2::assignTaxonomy()` and `MiscMetabar::add_new_taxonomy_pq()`
#'   reject. One of:
#'   - `"dada2"`: strip the prefixes to unprefixed, positional dada2
#'     (`>Bacteria;Pseudomonadota;...;`).
#'   - `"sintax"`: rewrite as `>ID;tax=d:Bacteria,p:...`.
#'   - `"keep"`: leave the original `d__`-prefixed headers untouched.
#'   Ignored for `format = "fasta"`.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' The dada2-formatted files are maintained by Benjamin Callahan on Zenodo
#' and are the same source as the SILVA dada2 training sets. See
#' <https://benjjneb.github.io/dada2/training.html> for details.
#'
#' The Greengenes2 trainset uses `d__`/`p__` rank prefixes. By default
#' (`tax_format = "dada2"`) the prefixes are stripped so the file is directly
#' usable by `dada2::assignTaxonomy()` and `add_new_taxonomy_pq()`.
#'
#' Please cite: McDonald D et al. (2024) Greengenes2 unifies microbial
#' data in a single reference tree. Nature Biotechnology 42:715-718.
#' \doi{10.1038/s41587-023-01845-1}
#' @seealso [format2dada2()], [tax_prefixes()]
#' @examples
#' \dontrun{
#' # Download dada2-formatted Greengenes2
#' download_greengenes2_db(dest_dir = "databases")
#'
#' # Download plain FASTA from FTP
#' download_greengenes2_db(dest_dir = "databases", format = "fasta")
#' }
download_greengenes2_db <- function(
  dest_dir = ".",
  version = "2024.09",
  format = c("dada2", "dada2_species", "fasta"),
  tax_format = c("dada2", "sintax", "keep"),
  verbose = TRUE
) {
  format <- match.arg(format)
  tax_format <- match.arg(tax_format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # Zenodo record IDs for dada2-formatted Greengenes2
  zenodo_records <- list(
    "2024.09" = "14169078"
  )

  version_us <- gsub("\\.", "_", version)

  if (format %in% c("dada2", "dada2_species")) {
    record_id <- zenodo_records[[version]]
    if (is.null(record_id)) {
      stop(
        "No known Zenodo record for Greengenes2 v",
        version,
        ". ",
        "Known versions: ",
        paste(names(zenodo_records), collapse = ", "),
        ". Visit https://benjjneb.github.io/dada2/training.html",
        call. = FALSE
      )
    }

    if (format == "dada2") {
      filename <- paste0("gg2_", version_us, "_toGenus_trainset.fa.gz")
    } else {
      filename <- paste0("gg2_", version_us, "_toSpecies_trainset.fa.gz")
    }

    url <- paste0(
      "https://zenodo.org/records/",
      record_id,
      "/files/",
      filename
    )
  } else {
    # Plain FASTA from Greengenes2 FTP
    filename <- paste0(version, ".seqs.fna.gz")
    url <- paste0(
      "https://ftp.microbio.me/greengenes_release/",
      version,
      "/",
      filename
    )
  }

  dest_file <- file.path(dest_dir, filename)
  download_file(url, dest_file, verbose = verbose)

  # The dada2/dada2_species trainsets carry d__/p__ prefixes; rewrite to plain
  # dada2 (or sintax) so the file feeds assignTaxonomy()/add_new_taxonomy_pq().
  if (format %in% c("dada2", "dada2_species") && tax_format != "keep") {
    if (verbose) {
      message("Rewriting Greengenes2 headers as ", tax_format, " ...")
    }
    .reformat_inheader_fasta(
      fasta_path = dest_file,
      header_sep = ";",
      tax_format = tax_format,
      output_path = dest_file,
      id_prefix = "GG2_",
      verbose = verbose
    )
  }

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# RDP
# ——————————————————————————————————————————————————————————————————————

#' Download an RDP reference database
#'
#' @description
#' Downloads the Ribosomal Database Project (RDP) 16S rRNA database.
#' By default, downloads the dada2-formatted training sets from Zenodo
#' (maintained by Benjamin Callahan).
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param trainset (Character, default `"19"`) RDP trainset version number.
#' @param format (Character, default `"dada2"`) One of:
#'   - `"dada2"`: training set for `dada2::assignTaxonomy()`.
#'   - `"dada2_species"`: species assignment file for
#'     `dada2::addSpecies()`.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' The dada2-formatted files are maintained by Benjamin Callahan on
#' Zenodo. See <https://benjjneb.github.io/dada2/training.html> for
#' details.
#'
#' Please cite: Cole JR et al. (2014) Ribosomal Database Project: data
#' and tools for high throughput rRNA analysis. Nucleic Acids Research
#' 42:D633-D642. \doi{10.1093/nar/gkt1244}
#' @seealso [format2dada2()], [download_silva_db()]
#' @examples
#' \dontrun{
#' # Download RDP trainset 19 for assignTaxonomy()
#' download_rdp_db(dest_dir = "databases")
#'
#' # Download species assignment file
#' download_rdp_db(dest_dir = "databases", format = "dada2_species")
#' }
download_rdp_db <- function(
  dest_dir = ".",
  trainset = "19",
  format = c("dada2", "dada2_species"),
  verbose = TRUE
) {
  format <- match.arg(format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # Zenodo record IDs for dada2-formatted RDP
  zenodo_records <- list(
    "19" = "14168771",
    "18" = "4310151",
    "16" = "801828"
  )

  record_id <- zenodo_records[[trainset]]
  if (is.null(record_id)) {
    stop(
      "No known Zenodo record for RDP trainset ",
      trainset,
      ". ",
      "Known trainsets: ",
      paste(names(zenodo_records), collapse = ", "),
      ". Visit https://benjjneb.github.io/dada2/training.html",
      call. = FALSE
    )
  }

  if (format == "dada2") {
    filename <- paste0("rdp_train_set_", trainset, ".fa.gz")
  } else {
    filename <- paste0("rdp_species_assignment_", trainset, ".fa.gz")
  }

  url <- paste0(
    "https://zenodo.org/records/",
    record_id,
    "/files/",
    filename
  )

  dest_file <- file.path(dest_dir, filename)
  download_file(url, dest_file, verbose = verbose)

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# MIDORI2
# ——————————————————————————————————————————————————————————————————————

#' Download a MIDORI2 reference database
#'
#' @description
#' Downloads the MIDORI2 reference database for eukaryotic mitochondrial
#' genes (COI, 12S, 16S, Cytb, etc.). MIDORI2 provides pre-formatted
#' FASTA files for multiple classifiers (dada2, SINTAX, RDP, BLAST).
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param gene (Character, default `"CO1"`) Mitochondrial gene marker.
#'   Common values: `"CO1"`, `"srRNA"` (12S), `"lrRNA"` (16S), `"Cytb"`.
#' @param format (Character, default `"dada2"`) One of `"dada2"`,
#'   `"dada2_species"`, `"SINTAX"`, `"RDP"`, or `"BLAST"`.
#' @param seq_type (Character, default `"UNIQ"`) One of `"UNIQ"` (all
#'   unique haplotypes per species) or `"LONGEST"` (single longest
#'   sequence per species).
#' @param url (Character) Direct download URL. If `NULL` (default), the
#'   function provides instructions and the download page URL.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly), or a message
#'   with download instructions if no URL is provided.
#' @export
#' @author Adrien Taudière
#' @details
#' MIDORI2 download URLs include a date-stamped directory path that
#' changes with each GenBank release, making fully programmatic access
#' fragile. Visit <https://www.reference-midori.info/download.php> to
#' find the current download URL for your desired gene and format, then
#' pass it via the `url` parameter.
#'
#' Files are typically named following this pattern:
#' `MIDORI2_{TYPE}_NUC_SP_GB{VERSION}_{GENE}_{FORMAT}.fasta.gz`
#'
#' Please cite: Leray M et al. (2022) MIDORI2: A collection of quality
#' controlled, preformatted, and regularly updated reference databases
#' for taxonomic assignment of eukaryotic mitochondrial sequences.
#' Environmental DNA 4:894-907. \doi{10.1002/edn3.303}
#' @seealso [format2sintax()], [format2dada2()]
#' @examples
#' \dontrun{
#' # Get instructions for downloading MIDORI2
#' download_midori2_db()
#'
#' # Download with a specific URL
#' download_midori2_db(
#'   dest_dir = "databases",
#'   url = "https://reference-midori.info/download/Databases/..."
#' )
#' }
download_midori2_db <- function(
  dest_dir = ".",
  gene = "CO1",
  format = c("dada2", "dada2_species", "SINTAX", "RDP", "BLAST"),
  seq_type = c("UNIQ", "LONGEST"),
  url = NULL,
  verbose = TRUE
) {
  format <- match.arg(format)
  seq_type <- match.arg(seq_type)

  if (is.null(url)) {
    format_dir <- switch(
      format,
      dada2 = "DADA2",
      dada2_species = "DADA2_sp",
      SINTAX = "SINTAX",
      RDP = "RDP",
      BLAST = "BLAST"
    )
    message(
      "MIDORI2 download URLs change with each GenBank release.\n",
      "Please visit the download page to get the URL for your desired ",
      "gene and format:\n",
      "  https://www.reference-midori.info/download.php\n\n",
      "Look for a file matching this pattern:\n",
      "  MIDORI2_",
      seq_type,
      "_NUC_SP_GB{VERSION}_",
      gene,
      "_",
      toupper(format_dir),
      ".fasta.gz\n\n",
      "Then call:\n",
      "  download_midori2_db(url = 'https://...')"
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


# ——————————————————————————————————————————————————————————————————————
# DIAT.barcode
# ——————————————————————————————————————————————————————————————————————

#' Download a Diat.barcode reference database
#'
#' @description
#' Downloads the Diat.barcode reference database for diatom rbcL barcoding.
#' This is a curated database for diatom identification using the rbcL
#' marker gene. The recommended access method is through the
#' [diatbarcode](https://github.com/fkeck/diatbarcode) R package, which
#' provides additional tools for working with the database.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param format (Character, default `"dada2"`) One of `"dada2"` or
#'   `"dada2_species"`. Uses dada2-formatted files from the INRAE Dataverse.
#' @param url (Character) Direct download URL. If `NULL` (default), the
#'   function provides instructions for using the `diatbarcode` R package.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly), or a message
#'   with download instructions if no URL is provided.
#' @export
#' @author Adrien Taudière
#' @details
#' The Diat.barcode database is maintained by INRAE and hosted on
#' Recherche Data Gouv. For more advanced access (metadata, full taxonomy
#' tables, custom queries), consider using the
#' [diatbarcode](https://github.com/fkeck/diatbarcode) R package
#' directly:
#'
#' ```
#' diatbarcode::download_diatbarcode(
#'   path = "databases",
#'   flavor = "rbcl312_dada2_tax"
#' )
#' ```
#'
#' Please cite: Rimet F et al. (2019) Diat.barcode, an open-access
#' curated barcode library for diatoms. Scientific Reports 9:15116.
#' \doi{10.1038/s41598-019-51500-6}
#' @examples
#' \dontrun{
#' download_diatbarcode_db(dest_dir = "databases")
#' }
download_diatbarcode_db <- function(
  dest_dir = ".",
  format = c("dada2", "dada2_species"),
  url = NULL,
  verbose = TRUE
) {
  format <- match.arg(format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (is.null(url)) {
    message(
      "Diat.barcode files are hosted on INRAE Dataverse.\n",
      "The recommended approach is to use the diatbarcode R package:\n",
      "  diatbarcode::download_diatbarcode(\n",
      "    path = '",
      dest_dir,
      "',\n",
      "    flavor = '",
      ifelse(format == "dada2", "rbcl312_dada2_tax", "rbcl312_dada2_spe"),
      "'\n",
      "  )\n\n",
      "Alternatively, visit:\n",
      "  https://entrepot.recherche.data.gouv.fr/dataset.xhtml",
      "?persistentId=doi:10.15454/HNI1EK\n",
      "and pass the direct file download URL via the `url` parameter."
    )
    return(invisible(NULL))
  }

  filename <- basename(url)
  dest_file <- file.path(dest_dir, filename)

  download_file(url, dest_file, verbose = verbose)

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# KSGP
# ——————————————————————————————————————————————————————————————————————

# Parse one KSGP .tax lineage into a named character vector whose names are
# the **original** prefix letters (e.g. "k", "p", "c", ...). Unlike
# `.lineage_to_ranks()` — which collapses both `d` and `k` to the canonical
# `d` rank key — this helper preserves the letter the source file actually
# uses, so the SINTAX renderer emits `k:Bacteria` (not `d:Bacteria`) for a
# KSGP line that starts with `k__Bacteria`.
#
# The value is taken as everything after the first `__` (greedy), which
# is what KSGP needs: compartment-tagged values such as
# `Eukaryota__mito` are kept as a single value rather than being split on
# the inner `__`.
.lineage_to_ranks_ksgp <- function(lineage, sep = ";") {
  if (length(lineage) != 1L || is.na(lineage) || !nzchar(trimws(lineage))) {
    return(character(0))
  }
  tokens <- strsplit(lineage, sep, fixed = TRUE)[[1]]
  out <- character(0)
  for (tok in tokens) {
    tok <- trimws(tok)
    if (!nzchar(tok)) {
      next
    }
    pm <- regmatches(tok, regexec("^([a-zA-Z])__(.+)$", tok))[[1]]
    if (length(pm) != 3L) {
      next
    }
    letter <- tolower(pm[[2]])
    value <- pm[[3]]
    if (.is_missing_tax(value)) {
      next
    }
    out[[letter]] <- value
  }
  out
}


#' Download the KSGP or GTDB+ reference database
#'
#' @description
#' Downloads the KSGP (Karst, Silva, GTDB, and PR2) reference database for
#' SSU rRNA taxonomic assignment, particularly optimized for Archaea
#' communities. KSGP combines near full-length rRNA sequences from Karst
#' et al. 2018, re-annotated SILVA prokaryote SSU sequences, cleaned GTDB 16S
#' sequences, PR2 eukaryote 18S sequences, and MIDORI2 mitochondrial
#' sequences. Taxonomy is based on GTDB, providing phylogenetically consistent
#' classification.
#'
#' Also provides access to the GTDB+ and GTDB_cleaned databases built as
#' intermediate steps during KSGP construction.
#'
#' Three annotation variants are available for `database = "KSGP"` and
#' `file_type = "tax"`:
#' - `"sintax"` (default): SINTAX-based taxonomic assignments (KSGP Sintax
#'   in the paper). Available for all versions.
#' - `"lca"`: Conservative lowest common ancestor assignments (KSGP LCA).
#'   Only available for version `"3.1"`.
#' - `"ksgp_plus"`: Similarity-clustered putative taxa (KSGP+). Only
#'   available for version `"3.1"`.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded file.
#' @param database (Character, default `"KSGP"`) One of:
#'   - `"KSGP"`: Full KSGP SSU database (Archaea + Bacteria + Eukaryota).
#'   - `"GTDB_plus"`: Cleaned GTDB 16S sequences with PR2 and MIDORI2.
#'   - `"GTDB_cleaned"`: Cleaned GTDB 16S sequences only (no eukaryote
#'     supplement).
#' @param file_type (Character, default `"fasta"`) One of:
#'   - `"fasta"`: FASTA file with SSU sequences.
#'   - `"tax"`: Taxonomy file (`.tax`) with taxonomic annotations.
#'   - `"archive"`: Complete `.tar.gz` archive (all KSGP files, all
#'     annotation variants). Only available for `database = "KSGP"`.
#' @param annotation (Character, default `"lca"`) Taxonomic annotation
#'   method. One of `"lca"`, `"sintax"`, or `"ksgp_plus"`. Used to pick
#'   the matching `.tax` file when `file_type = "tax"`, and to pick the
#'   taxonomy merged into the FASTA headers when `file_type = "fasta"`
#'   and `tax_format != "none"`. The `lca` annotation has the broadest
#'   sequence coverage and is the default for a fully-annotated KSGP
#'   FASTA. Only `"sintax"` is available for version `"1.0"`.
#' @param tax_format (Character, default `"dada2"`) When `file_type = "fasta"`,
#'   also download the companion `.tax` file and merge its taxonomy into the
#'   FASTA headers (matched by sequence ID), so the file feeds
#'   `MiscMetabar::add_new_taxonomy_pq()`. One of `"dada2"`, `"sintax"`, or
#'   `"none"` (keep accession-only headers). Sequences whose ID is absent from
#'   the `.tax` (e.g. the SILVA-derived portion) keep accession-only headers.
#'   Ignored for `file_type = "tax"` / `"archive"`.
#' @param version (Character, default `"3.1"`) KSGP version. Known versions:
#'   `"3.1"` (2025, recommended) and `"1.0"`.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#' @param timeout (Numeric, default `Inf`) Timeout in seconds for each
#'   HTTP request. The default disables R's 60-second timeout so the
#'   multi-hundred-MB to multi-GB downloads (KSGP FASTA, the v3.1 archive)
#'   can complete. Set to a positive number of seconds to restore a
#'   strict timeout.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' When `file_type = "fasta"`, the function downloads the matching
#' `KSGP_v<version>.tar.gz` archive (one HTTP request) and extracts the
#' FASTA — and, when `tax_format != "none"`, the chosen `.tax` file — to
#' `dest_dir`, then removes the archive. The archive is roughly 3.5x
#' smaller than the raw FASTA (e.g. ~686 MB vs ~2.4 GB for v3.1), so
#' this is both faster and lighter on the server than two separate
#' requests. The KSGP FASTA and taxonomy files are otherwise separate
#' downloads.
#'
#' With `tax_format = "sintax"` (or `"dada2"`), the taxonomy is merged
#' into the FASTA headers (one sequence ID per row, matched against the
#' `.tax` file) and the `.tax` file is removed, so the result is a
#' single FASTA ready for VSEARCH/dada2 — the original prefix letters
#' from the `.tax` are preserved in the SINTAX output (a KSGP line
#' starting with `k__Bacteria;` becomes `>ID;tax=k:Bacteria,...`,
#' not `d:Bacteria,...`). To use KSGP for taxonomic assignment:
#' - With VSEARCH SINTAX: download the FASTA (`file_type = "fasta"`,
#'   `tax_format = "sintax"`).
#' - With dada2: download the FASTA (`file_type = "fasta"`,
#'   `tax_format = "dada2"`).
#' - With LotuS2: the KSGP database is integrated directly.
#' - For a complete set of all files: use `file_type = "archive"`.
#'
#' KSGP substantially improves Archaea annotation over SILVA and Greengenes2:
#' Class and Order assignments increase by 2.7x and 4.2x respectively.
#'
#' Please cite: Grant A et al. (2025) KSGP 3.1: improved taxonomic annotation
#' of Archaea communities using LotuS2, the genome taxonomy database and
#' RNAseq data. ISME Communications 5(1): ycaf094.
#' \doi{10.1093/ismeco/ycaf094}
#' @seealso [download_silva_db()], [download_pr2_db()], [format2sintax()]
#' @examples
#' \dontrun{
#' # Download KSGP v3.1 FASTA
#' download_ksgp_db(dest_dir = "databases")
#'
#' # Download KSGP v3.1 LCA taxonomy file
#' download_ksgp_db(
#'   dest_dir = "databases",
#'   file_type = "tax",
#'   annotation = "lca"
#' )
#'
#' # Download KSGP+ taxonomy file
#' download_ksgp_db(
#'   dest_dir = "databases",
#'   file_type = "tax",
#'   annotation = "ksgp_plus"
#' )
#'
#' # Download the complete KSGP archive (all annotation variants)
#' download_ksgp_db(dest_dir = "databases", file_type = "archive")
#'
#' # Download GTDB+ (cleaned GTDB + PR2 + MIDORI2)
#' download_ksgp_db(dest_dir = "databases", database = "GTDB_plus")
#' }
download_ksgp_db <- function(
  dest_dir = ".",
  database = c("KSGP", "GTDB_plus", "GTDB_cleaned"),
  file_type = c("fasta", "tax", "archive"),
  annotation = c("lca", "sintax", "ksgp_plus"),
  tax_format = c("dada2", "sintax", "none"),
  version = "3.1",
  verbose = TRUE,
  timeout = Inf
) {
  database <- match.arg(database)
  file_type <- match.arg(file_type)
  annotation <- match.arg(annotation)
  tax_format <- match.arg(tax_format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # Explicit lookup of confirmed-valid filenames.
  # Keys: "version:database:file_type:annotation"
  # For non-KSGP databases or non-tax file types, annotation is ignored
  # (canonicalised to "sintax" in key construction below).
  # Note: GTDB_cleaned v1.0 .tax has a server-side typo (GTB not GTDB).
  file_lookup <- list(
    # v3.1 — KSGP
    "3.1:KSGP:fasta:sintax" = "KSGP_v3.1.fasta",
    "3.1:KSGP:fasta:lca" = "KSGP_v3.1.fasta",
    "3.1:KSGP:fasta:ksgp_plus" = "KSGP_v3.1.fasta",
    "3.1:KSGP:tax:sintax" = "KSGP_v3.1.tax",
    "3.1:KSGP:tax:lca" = "KSGP_lca_v3.1.tax",
    "3.1:KSGP:tax:ksgp_plus" = "KSGP_plus_v3.1.tax",
    "3.1:KSGP:archive:sintax" = "KSGP_v3.1.tar.gz",
    # v3.1 — GTDB_plus
    "3.1:GTDB_plus:fasta:sintax" = "GTDB_plus_v3.1.fasta",
    "3.1:GTDB_plus:tax:sintax" = "GTDB_plus_v3.1.tax",
    # v3.1 — GTDB_cleaned
    "3.1:GTDB_cleaned:fasta:sintax" = "GTDB_cleaned_v3.1.fasta",
    "3.1:GTDB_cleaned:tax:sintax" = "GTDB_cleaned_v3.1.tax",
    # v1.0 — KSGP (lca/ksgp_plus variants did not exist in v1.0)
    "1.0:KSGP:fasta:sintax" = "KSGP_v1.0.fasta",
    "1.0:KSGP:tax:sintax" = "KSGP_v1.0.tax",
    "1.0:KSGP:archive:sintax" = "KSGP_v1.0.tar.gz",
    # v1.0 — GTDB_plus
    "1.0:GTDB_plus:fasta:sintax" = "GTDB_plus_v1.0.fasta",
    "1.0:GTDB_plus:tax:sintax" = "GTDB_plus_v1.0.tax",
    # v1.0 — GTDB_cleaned (server-side typo: GTB_cleaned, not GTDB_cleaned)
    "1.0:GTDB_cleaned:fasta:sintax" = "GTDB_cleaned_v1.0.fasta",
    "1.0:GTDB_cleaned:tax:sintax" = "GTB_cleaned_v1.0.tax"
  )

  # annotation only differentiates KSGP .tax files; all other combinations
  # map to the same file regardless of annotation
  lookup_annotation <- if (database == "KSGP" && file_type == "tax") {
    annotation
  } else {
    "sintax"
  }

  key <- paste(version, database, file_type, lookup_annotation, sep = ":")
  filename <- file_lookup[[key]]

  if (is.null(filename)) {
    avail <- names(file_lookup)[
      startsWith(names(file_lookup), paste0(version, ":"))
    ]
    avail_desc <- unique(vapply(
      avail,
      function(k) {
        p <- strsplit(k, ":")[[1]]
        suffix <- if (p[2] == "KSGP" && p[3] == "tax") {
          paste0(", annotation = '", p[4], "'")
        } else {
          ""
        }
        paste0("  database='", p[2], "', file_type='", p[3], "'", suffix)
      },
      character(1)
    ))
    stop(
      "No known KSGP download for version='",
      version,
      "', database='",
      database,
      "', file_type='",
      file_type,
      "'",
      if (database == "KSGP" && file_type == "tax") {
        paste0(", annotation='", annotation, "'")
      },
      ".\n",
      "Known combinations for version '",
      version,
      "':\n",
      paste(avail_desc, collapse = "\n"),
      "\n",
      "Visit https://ksgp.earlham.ac.uk/index.php?site=download for details.",
      call. = FALSE
    )
  }

  url <- paste0(
    "https://ksgp.earlham.ac.uk/downloads/v",
    version,
    "/",
    filename
  )
  dest_file <- file.path(dest_dir, filename)

  # FASTA downloads are routed through the tar.gz archive (~686 MB
  # compressed vs. ~2.4 GB raw) so only one HTTP request is needed and
  # the transfer is ~3.5x smaller. The archive also contains every
  # annotation variant of the .tax file, so a second download is not
  # required for `tax_format != "none"`.
  tax_filename_inline <- NULL
  if (file_type == "fasta") {
    archive_name <- file_lookup[[paste(
      version,
      database,
      "archive",
      "sintax",
      sep = ":"
    )]]
    if (is.null(archive_name)) {
      # Fallback for hypothetical lookup gaps: use the raw FASTA directly.
      download_file(url, dest_file, verbose = verbose, timeout = timeout)
    } else {
      archive_url <- paste0(
        "https://ksgp.earlham.ac.uk/downloads/v",
        version,
        "/",
        archive_name
      )
      archive_path <- file.path(dest_dir, archive_name)
      download_file(
        archive_url,
        archive_path,
        verbose = verbose,
        timeout = timeout
      )

      # Pre-pick the .tax filename we'll also need, if any, so a single
      # `untar()` call can extract both files in one pass. For the KSGP
      # FASTA workflow the user-selected `annotation` chooses which
      # variant (sintax / lca / ksgp_plus) to merge in. Non-KSGP
      # databases only ship a sintax .tax.
      if (tax_format != "none") {
        fasta_annotation <- if (database == "KSGP") {
          annotation
        } else {
          if (annotation != "sintax") {
            warning(
              "database='",
              database,
              "' only has a 'sintax' .tax; ignoring annotation='",
              annotation,
              "'.",
              call. = FALSE
            )
          }
          "sintax"
        }
        tax_filename_inline <- file_lookup[[paste(
          version,
          database,
          "tax",
          fasta_annotation,
          sep = ":"
        )]]
      }
      to_extract <- c(basename(filename), tax_filename_inline)
      to_extract <- to_extract[nzchar(to_extract)]

      if (verbose) {
        message(
          "Extracting ",
          paste(to_extract, collapse = " + "),
          " from ",
          archive_name,
          " ..."
        )
      }
      utils::untar(
        archive_path,
        files = to_extract,
        exdir = dest_dir,
        list = FALSE
      )
      if (!file.exists(dest_file) || file.size(dest_file) == 0L) {
        # The lookup assumed a flat archive layout (files at the top
        # level); if extraction did not produce the FASTA where we
        # expect it, surface the full archive listing to help debug.
        listing <- tryCatch(
          utils::untar(archive_path, list = TRUE),
          error = function(e) character(0)
        )
        unlink(archive_path)
        stop(
          "Expected to find ",
          basename(filename),
          " at ",
          dest_file,
          " after extracting ",
          archive_name,
          ", but it is missing. ",
          "Archive contents:\n  ",
          paste(listing, collapse = "\n  "),
          call. = FALSE
        )
      }
      # Free the ~686 MB archive as soon as we have what we need.
      unlink(archive_path)
    }
  } else {
    download_file(url, dest_file, verbose = verbose, timeout = timeout)
  }

  if (verbose && file_type == "archive") {
    message(
      "KSGP archive saved as: ",
      dest_file,
      "\n",
      "Extract with: untar('",
      dest_file,
      "', exdir = '",
      dest_dir,
      "')"
    )
  }

  # For the FASTA, optionally merge the companion .tax (matched by sequence
  # ID, as in the KSGP/LotuS2 workflow) and rewrite headers as dada2/sintax.
  # Sequences whose ID is absent from the .tax keep accession-only headers.
  if (file_type == "fasta" && tax_format != "none") {
    tax_filename <- if (!is.null(tax_filename_inline)) {
      tax_filename_inline
    } else {
      file_lookup[[paste(
        version,
        database,
        "tax",
        lookup_annotation,
        sep = ":"
      )]]
    }
    if (is.null(tax_filename)) {
      warning(
        "No .tax file known for this version/database/annotation; ",
        "FASTA headers left unannotated.",
        call. = FALSE
      )
    } else {
      if (verbose) {
        message(
          "Merging taxonomy from ",
          tax_filename,
          " into ",
          tax_format,
          " headers ..."
        )
      }
      # When the FASTA came from the archive, the .tax is already
      # extracted to dest_dir. Otherwise, download it directly.
      tax_path <- file.path(dest_dir, tax_filename)
      if (!file.exists(tax_path) || file.size(tax_path) == 0L) {
        tax_url <- paste0(
          "https://ksgp.earlham.ac.uk/downloads/v",
          version,
          "/",
          tax_filename
        )
        download_file(tax_url, tax_path, verbose = FALSE, timeout = timeout)
      }
      if (!file.exists(tax_path) || file.size(tax_path) == 0L) {
        warning(
          "Could not retrieve ",
          tax_filename,
          "; FASTA headers left unannotated.",
          call. = FALSE
        )
        tax_path <- NULL
      }
      tax_tab <- utils::read.table(
        tax_path,
        sep = "\t",
        quote = "",
        comment.char = "",
        stringsAsFactors = FALSE,
        col.names = c("id", "tax")
      )
      id2ranks <- stats::setNames(
        lapply(tax_tab$tax, .lineage_to_ranks_ksgp, sep = ";"),
        tax_tab$id
      )
      .write_tax_fasta(
        fasta_path = dest_file,
        id2ranks = id2ranks,
        tax_format = tax_format,
        output_path = dest_file,
        verbose = verbose
      )
      # The user wants a single FASTA with taxonomy in the header, not
      # the .tax file left alongside it. Remove the extracted .tax.
      if (file.exists(tax_path)) {
        unlink(tax_path)
      }
    }
  }

  invisible(dest_file)
}


# ——————————————————————————————————————————————————————————————————————
# LTPlus
# ——————————————————————————————————————————————————————————————————————

#' Download the LTPlus reference database
#'
#' @description
#' Downloads the LTPlus 16S rRNA gene reference FASTA for Bacteria and
#' Archaea. LTPlus extends the All-Species Living Tree Project (LTP)
#' type-strain collection with the best-quality non-type sequences selected
#' from the SILVA non-redundant and GTDB databases, plus the highest-quality
#' 16S sequences deposited at NCBI between 2019 and 2025. Sequences are
#' clustered non-redundantly at a 98.7% identity threshold, yielding a
#' compact database that covers most of the known prokaryotic genealogical
#' diversity.
#'
#' @param dest_dir (Character, default `"."`) Directory to save the
#'   downloaded FASTA file.
#' @param url (Character) Direct download URL for the LTPlus FASTA. Defaults
#'   to the February 2026 release served by the Marine Microbiology Group
#'   (IMEDEA, UIB-CSIC). Pass a different release URL to download another
#'   version (see Details).
#' @param tax_format (Character, default `"dada2"`) Taxonomy format to write
#'   into the FASTA headers, so the file can feed
#'   `MiscMetabar::add_new_taxonomy_pq()`. One of:
#'   - `"dada2"`: unprefixed, semicolon-delimited ranks
#'     (`>Bacteria;Pseudomonadota;...;`).
#'   - `"sintax"`: `>ID;tax=d:Bacteria,p:Pseudomonadota,...`.
#'   - `"none"`: keep the original accession-only headers.
#'   Taxonomy is read from the companion CSV (see `csv_url`).
#' @param csv_url (Character) URL of the LTPlus metadata CSV that maps each
#'   sequence accession to its full taxonomy. Defaults to the CSV of the
#'   February 2026 release. Only used when `tax_format != "none"`.
#' @param to_dna (Logical, default `TRUE`) Convert the downloaded RNA FASTA
#'   to DNA (transcribe `U` to `T`) and rewrite it as a standard FASTA. Set
#'   to `FALSE` to keep the original RNA file unchanged. Requires the
#'   \pkg{Biostrings} package.
#' @param verbose (Logical, default `TRUE`) Print progress messages.
#'
#' @returns The path to the downloaded file (invisibly).
#' @export
#' @author Adrien Taudière
#' @details
#' The file is the LTPlus 16S FASTA exported from the underlying curated
#' alignment with gap columns removed ("compressed"), so the sequences are
#' **unaligned** and vary in length (~140 MB total). It is served directly
#' (no registration) from the LTP release backend; the file name is taken
#' from the server's `Content-Disposition` header when available (e.g.
#' `ltplus_10_02_2026_compressed.fasta`).
#'
#' The released sequences are in the **RNA alphabet** (`U` rather than `T`)
#' and the sequence lines contain whitespace. With `to_dna = TRUE` (default)
#' the function transcribes `U` to `T` and rewrites a clean, whitespace-free
#' DNA FASTA in place, ready for DNA-based classifiers such as dada2 or
#' VSEARCH. With `to_dna = FALSE` the original RNA file is kept as-is.
#'
#' The released FASTA headers carry only an accession (e.g. `>LAJZ3046`); the
#' taxonomy lives in a companion CSV. With `tax_format = "dada2"` (default)
#' or `"sintax"` the function downloads that CSV, maps each accession to its
#' full LTPlus lineage, and rewrites the headers with taxonomy so the file is
#' ready for `MiscMetabar::add_new_taxonomy_pq()`. Use `tax_format = "none"`
#' to keep the accession-only headers.
#'
#' The default `url` points to the current release file. To list available
#' releases and files, see the Downloads section of
#' <https://bioinfo.uib.es/ltp/> or query
#' <https://biocom.uib.es/opucheck-backend/api/releases>; each file has an
#' id appended to `.../api/releases/` to form its download URL. The ARB
#' database, CSV and Newick tree files are also available there.
#'
#' Please cite: Rosselló-Móra R et al. (2026) A pipeline for improved 16S
#' rRNA gene-based phylogeny and diversity analyses of Bacteria and Archaea.
#' Research Square. \doi{10.21203/rs.3.rs-9370187/v1}
#' @seealso [download_silva_db()], [download_greengenes2_db()],
#'   [download_ksgp_db()]
#' @examples
#' \dontrun{
#' # Download the current LTPlus 16S FASTA (DNA, dada2 taxonomy headers)
#' download_ltplus_db(dest_dir = "databases")
#'
#' # SINTAX-formatted headers instead
#' download_ltplus_db(dest_dir = "databases", tax_format = "sintax")
#'
#' # Keep the original RNA, accession-only FASTA without conversion
#' download_ltplus_db(dest_dir = "databases", to_dna = FALSE, tax_format = "none")
#' }
download_ltplus_db <- function(
  dest_dir = ".",
  url = "https://biocom.uib.es/opucheck-backend/api/releases/02_26_06",
  tax_format = c("dada2", "sintax", "none"),
  csv_url = "https://biocom.uib.es/opucheck-backend/api/releases/02_26_02",
  to_dna = TRUE,
  verbose = TRUE
) {
  tax_format <- match.arg(tax_format)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # The release endpoint carries no file name in its path; prefer the
  # name advertised in the Content-Disposition header, falling back to the
  # URL basename or a generic LTPlus FASTA name.
  filename <- tryCatch(
    {
      headers <- curlGetHeaders(url, redirect = TRUE)
      cd <- grep(
        "content-disposition",
        headers,
        ignore.case = TRUE,
        value = TRUE
      )
      fn <- if (length(cd) > 0) {
        sub('.*filename="?([^";\r\n]+).*', "\\1", cd[[1]])
      } else {
        ""
      }
      if (is.na(fn) || fn == "" || fn == cd[[1]]) NA_character_ else fn
    },
    error = function(e) NA_character_
  )

  if (is.na(filename)) {
    filename <- sub("\\?.*$", "", basename(url))
    if (filename == "" || !grepl(".", filename, fixed = TRUE)) {
      filename <- "ltplus.fasta"
    }
  }

  dest_file <- file.path(dest_dir, filename)
  download_file(url, dest_file, verbose = verbose)

  if (to_dna) {
    if (!requireNamespace("Biostrings", quietly = TRUE)) {
      warning(
        "Package 'Biostrings' is required for `to_dna = TRUE`; ",
        "the RNA FASTA was downloaded but not converted.",
        call. = FALSE
      )
    } else {
      if (verbose) {
        message("Converting RNA (U) to DNA (T) and rewriting FASTA ...")
      }
      seqs <- suppressWarnings(Biostrings::readRNAStringSet(dest_file))
      dna <- Biostrings::DNAStringSet(seqs)
      # Write to a temporary file first, then replace, so a failure mid-write
      # does not leave a corrupted database file behind.
      tmp <- tempfile(tmpdir = dest_dir, fileext = ".fasta")
      Biostrings::writeXStringSet(dna, tmp)
      file.rename(tmp, dest_file)
      if (verbose) {
        message("Wrote DNA FASTA: ", dest_file)
      }
    }
  }

  if (tax_format != "none") {
    if (verbose) {
      message(
        "Fetching LTPlus taxonomy CSV and writing ",
        tax_format,
        " headers ..."
      )
    }
    csv_file <- tempfile(fileext = ".csv")
    on.exit(unlink(csv_file), add = TRUE)
    download_file(csv_url, csv_file, verbose = FALSE)
    meta <- utils::read.csv(
      csv_file,
      sep = ";",
      quote = "",
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    tax_col <- grep("taxonomy", names(meta), ignore.case = TRUE, value = TRUE)[
      1
    ]
    if (is.na(tax_col) || !"NAME" %in% names(meta)) {
      warning(
        "Could not find the expected 'NAME' and taxonomy columns in the ",
        "LTPlus CSV; headers left unannotated.",
        call. = FALSE
      )
    } else {
      id2ranks <- stats::setNames(
        lapply(meta[[tax_col]], .lineage_to_ranks, sep = "/"),
        meta[["NAME"]]
      )
      .write_tax_fasta(
        fasta_path = dest_file,
        id2ranks = id2ranks,
        tax_format = tax_format,
        output_path = dest_file,
        verbose = verbose
      )
    }
  }

  invisible(dest_file)
}
