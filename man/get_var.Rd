% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nc.R
\name{get_var}
\alias{get_var}
\title{Retrieve a variable as array or stars object.}
\usage{
get_var(
  x,
  var = get_varnames(x),
  bb = get_bounds(x),
  time = get_range(x, "time"),
  depth = get_range(x, "depth"),
  banded = TRUE,
  form = c("array", "stars")[2]
)
}
\arguments{
\item{x}{ncdf4 object}

\item{var}{character, one or more names of the variables to retrieve}

\item{bb}{a 4 element bounding box for subsetting ordered as
\code{[xmin, xmax, ymin, ymax]}}

\item{time}{POSIXct vector of one or more times to retrieve. These are matched the
closest known times in the object. See \code{get_time}  Default
is the first recorded time in the object.}

\item{depth}{numeric vector of one or more depths. These are matched the
closest known depths in the object. See \code{get_depth} Default
is the first depth in the object.  Ignored if \code{depth} is not
a dimension of the variable.}

\item{banded}{logical, if TRUE then retrieve mutliple bands (time/depth). If
FALSE then allow only one value for time and depth and degenerate dimensions}

\item{form}{character, either 'array' of 'stars' (default)
\itemize{
  \item{array an array or list of arrays, possibly degenerate to a matrix}
  \item{stars a stars object, possibly with band (time) and z (depth)}
}}
}
\description{
Data are stored as \code{[lon, lat, time]} or \code{[lon, lat, depth, time]}
Degenerate indices (dimension = 1) are discarded, so if a single time is
requested for a \code{[lon, lat, time]} variable then a single band object is
returned.
}
\details{
The requested bounding box coordinates are matched to the closest grid cell
centers, thus the output grids may differ in extent form the requested bounding
box.

Requested times and depths are considered contiguous - we are extracting slabs
of data after all. Currently the first and last times or depths requested mark
the inclusive bounds of the slab in those dimensions. Requesting a single time or
depth works perfectly well.  If you need disjoint bands (not contiguous bands) then
you will need to make a separate request for each.
}
