copernicus
================

# copernicus

Provides download, archiving and access to
[Copernicus](https://marine.copernicus.eu/) marine local datasets.

### Requirements

  - [R v4+](https://www.r-project.org/)
  - [rlang](https://CRAN.R-project.org/package=rlang)
  - [dplyr](https://CRAN.R-project.org/package=dplyr)
  - [ncdf4](https://CRAN.R-project.org/package=ncdf4)
  - [sf](https://CRAN.R-project.org/package=sf)
  - [stars](https://CRAN.R-project.org/package=stars)
  - [readr](https://CRAN.R-project.org/package=readr)
  - [twinkle](https://github.com/BigelowLab/twinkle)

### Installation

    remotes::install_github("BigelowLab/copernicus")

### Fetch one day of global-analysis-forecast-phy-001-024

Requesting one day (by date) will return a list of `stars` objects. We
can use the `bind_stars` from the [twinkle
package](https://github.com/BigelowLab/twinkle) to bind them all into
one object.

``` r
x <- fetch_copernicus(date = Sys.Date(), banded = FALSE) %>%
  twinkle::bind_stars()
```

    ## Warning in fetch_copernicus(date = Sys.Date(), banded = FALSE): unable to remove
    ## file:/dev/shm/copernicus3bd86d42cc9d9d.nc
