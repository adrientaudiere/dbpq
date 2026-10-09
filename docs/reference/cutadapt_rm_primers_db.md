# Remove primers from a FASTA database using cutadapt

[![lifecycle-experimental](https://img.shields.io/badge/lifecycle-experimental-orange)](https://adrientaudiere.github.io/MiscMetabar/articles/Rules.html#lifecycle)

Removes pairs of primers and flanking regions from a FASTA reference
database using [cutadapt](https://github.com/marcelm/cutadapt/). Uses
linked adapters to trim between forward and reverse primers.

## Usage

``` r
cutadapt_rm_primers_db(
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
  args_before_cutadapt = paste0("source ~/miniforge3/etc/profile.d/conda.sh ",
    "&& conda activate cutadaptenv && "),
  rc_primer_rev = TRUE,
  primer_fw_required = start_with_fw,
  primer_rev_required = FALSE,
  min_overlap = NULL,
  min_length = NULL
)
```

## Arguments

- ref_fasta:

  (Character, required) Path to a FASTA file (plain or gzip).

- output:

  (Character) Path to the output FASTA file. If NULL, defaults to
  `{basename}_cutadapted.fasta`.

- primer_fw:

  (Character, required) The forward primer DNA sequence.

- primer_rev:

  (Character, required) The reverse primer DNA sequence, as ordered (5'
  to 3' on the reverse strand). See `rc_primer_rev`.

- discard_untrimmed:

  (Logical, default `TRUE`) Discard sequences where primers were not
  found: a sequence is kept when every required primer is found, or when
  at least one primer is found if both are optional. Set to `FALSE` to
  keep these sequences untrimmed.

- nproc:

  (Integer, default `1`) Number of CPU cores for cutadapt.

- verbose:

  (Logical, default `TRUE`) Print summary statistics.

- cmd_is_run:

  (Logical, default `TRUE`) If FALSE, return the command string without
  executing it.

- return_file_path:

  (Logical, default `FALSE`) If TRUE, return the output file path
  instead of the command.

- start_with_fw:

  (Logical, default `FALSE`) If TRUE, the forward primer must be
  anchored at the start of the sequence.

- output_json:

  (Logical, default `FALSE`) If TRUE, write a JSON summary of the
  cutadapt process.

- error_tolerance:

  (Numeric, default `0.1`) Maximum error rate for primer matching.

- args_before_cutadapt:

  (Character) Shell commands to run before cutadapt (e.g., conda
  activation).

- rc_primer_rev:

  (Logical, default `TRUE`) Reverse-complement `primer_rev` before
  building the linked adapter. Reference sequences are in forward
  orientation, so only the reverse complement of the reverse primer
  occurs at their 3' end. Set to `FALSE` when `primer_rev` is already
  given in forward orientation.

- primer_fw_required:

  (Logical, default `start_with_fw`) Mark the forward primer as required
  (`;required`) or optional (`;optional`) in the linked adapter.

- primer_rev_required:

  (Logical, default `FALSE`) Mark the reverse primer as required
  (`;required`) or optional (`;optional`) in the linked adapter.

- min_overlap:

  (Integer, default `NULL`) Minimum overlap between a primer and a
  sequence (cutadapt `-O`, whose own default is 3). A partial primer
  shorter than `min_overlap` at the end of a sequence is ignored: set it
  to the primer length to require complete primer sites. If `NULL`, the
  cutadapt default is used.

- min_length:

  (Integer, default `NULL`) Discard sequences shorter than `min_length`
  after trimming (cutadapt `-m`), such as references that start at the
  reverse-primer site and are left empty. If `NULL`, no length filter is
  applied.

## Value

The cutadapt command string, or the output file path if
`return_file_path = TRUE`.

## Details

This function is mainly a wrapper of the work of others. Please cite
cutadapt
([doi:10.14806/ej.17.1.200](https://doi.org/10.14806/ej.17.1.200) ).

## Author

Adrien Taudière

## Examples

``` r
if (FALSE) { # \dontrun{
cutadapt_rm_primers_db(
  "database.fasta.gz",
  output = "db_cutadapted.fasta",
  primer_fw = "GCATCGATGAAGAACGCAGC",
  primer_rev = "TCCTCCGCTTATTGATATGC"
)
} # }
```
