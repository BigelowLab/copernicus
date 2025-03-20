#' Read one or more copernicus files
#' 
#' By default the function tries to return an object with (variables of x, y, time) 
#' dimensions.  If multiple times are provided, then each var must be equally
#' represented.
#' 
#' @export
#' @param db tibble, database of selected records
#' @param path char, the path to the data set
#' @return stars object
read_copernicus = function(db, path){
  
  db$datetime = as.POSIXct(paste(format(db$date, '%Y-%m-%d'), db$time), 
                       format = "%Y-%m-%d %H%M%S", tz = 'UTC')  
  db$file = compose_filename(db, path)
  # read each variable
  # check that each variable has the same time-dim
  # if ok then bind, otherwise error
  db |>
    dplyr::group_by(.data$variable) |>
    dplyr::group_map(
      function(tbl, key){
        if (nrow(tbl) > 1 ){
          s = stars::read_stars(tbl$file, along = list(time = tbl$datetime)) |>
            rlang::set_names(tbl$variable[1])
        } else {
          s = stars::read_stars(tbl$file) |>
            rlang::set_names(tbl$variable[1])
        }
      }, .keep = TRUE) |>
    bind_stars()
}


#' Unpack a copernicus ncdf4 file
#'
#' @export
#' @param filename character, the full path specification
#' @param banded logical, see \code{\link{get_var}}.  Setting to FALSE
#'        returns single band objects (depth and time dropped)
#' @return list of \code{stars} objects
unpack_copernicus <- function(filename, banded = TRUE){
  x <- ncdf4::nc_open(filename[1])
  ss <- sapply(get_varnames(x),
               function(vname){
                 get_var(x, var = vname, banded = banded)
               },
               simplify = FALSE)
  ncdf4::nc_close(x)
  if (banded) ss = bind_stars(ss)
  ss
}

