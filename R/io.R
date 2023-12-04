#' Unpack a copernicus ncdf4 file
#'
#' @export
#' @param filename character, the full path specification
#' @param banded logical, see \code{\link{get_var}}.  Setting to FALSE
#'        returns single band objects (depth and time dropped)
#' @return list of \code{stars} objects
unpack_copernicus <- function(filename, banded = FALSE){
  x <- ncdf4::nc_open(filename[1])
  ss <- sapply(get_varnames(x),
               function(vname){
                 get_var(x, var = vname, banded = banded)
               },
               simplify = FALSE)
  ncdf4::nc_close(x)
  ss
}

