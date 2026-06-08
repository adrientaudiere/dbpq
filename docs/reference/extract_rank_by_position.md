# Extract a taxonomic rank by position from FASTA headers

Extract a taxonomic rank by position from FASTA headers

## Usage

``` r
extract_rank_by_position(headers, position, sep = ";")
```

## Arguments

- headers:

  Character vector of FASTA header lines.

- position:

  Integer, the 1-based position of the rank in the semicolon-delimited
  taxonomy string.

- sep:

  Character, delimiter between ranks (default `";"`).

## Value

A character vector of extracted rank values (NA where missing).
