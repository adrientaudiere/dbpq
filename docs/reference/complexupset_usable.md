# Is ComplexUpset usable with the installed ggplot2?

ComplexUpset on CRAN (\<= 1.3.3) is incompatible with ggplot2 \>= 4.0.0,
and merely *loading* such a build registers an `update_ggplot` method
that breaks ggplot2 4.0's `+` operator for every package. The fix lives
in the GitHub dev version (\>= 1.3.6, see krassowski/complex-upset#217).
We therefore decide usability from the installed metadata **without
loading the namespace**
([`system.file()`](https://rdrr.io/r/base/system.file.html) and
[`packageVersion()`](https://rdrr.io/r/utils/packageDescription.html) do
not load it): ComplexUpset is considered usable when ggplot2 is older
than 4.0.0, or when ComplexUpset is at least 1.3.6.

## Usage

``` r
complexupset_usable()
```
