# Remove primers from a FASTA database using cutadapt

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
    "&& conda activate cutadaptenv && ")
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

  (Character, required) The reverse primer DNA sequence.

- discard_untrimmed:

  (Logical, default `TRUE`) Discard sequences where primers were not
  found.

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
