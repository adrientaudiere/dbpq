# Download a file with progress and validation

Download a file with progress and validation

## Usage

``` r
download_file(url, dest_path, verbose = TRUE, timeout = Inf)
```

## Arguments

- url:

  The URL to download from.

- dest_path:

  The local file path to save to.

- verbose:

  Print progress messages.

- timeout:

  (Numeric, default `Inf`) Timeout in seconds passed to
  [`utils::download.file()`](https://rdrr.io/r/utils/download.file.html)
  via `options(timeout = ...)` for the duration of the call. `Inf`
  disables the timeout, which is needed for multi-GB reference databases
  such as KSGP (\>2 GB) and SILVA trainsets that take longer than R's
  60-second default to download.

## Value

The path to the downloaded file (invisibly).
