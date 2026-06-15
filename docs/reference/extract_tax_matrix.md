# Extract a taxonomy matrix from a phyloseq object or FASTA file

Extract a taxonomy matrix from a phyloseq object or FASTA file

## Usage

``` r
extract_tax_matrix(x, tax_format = "auto")
```

## Arguments

- x:

  A file path (character) or a phyloseq object.

- tax_format:

  Taxonomy format (only used for file input).

## Value

A character matrix with rows = taxa and columns = ranks.
