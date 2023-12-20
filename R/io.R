#' Read one or more copernicus files
#' 
#' By default the function tries to return a object with (variable, x, y, depth, time) 
#' dimensions.
#' 
#' @export
#' @param db tibble, database of selected records
#' @param path char, the path to the data set
#' @param depth NULL or numeric, the values to assign as depth. If NULL then
#'   the returned has dimensionality of (variable, x, y, time), but be advised
#'   you might get unexpectedly ordered time dimension if there are
#'   duplicate times. Depths can be passed as character type. 
#' @return stars object
read_copernicus = function(db, path, depth = as.numeric(db$depth)){
  
  if (!is.null(depth)) db$numdepth = depth
  db$datetime = as.POSIXct(paste(format(db$date, '%Y-%m-%d'), db$time), 
                       format = "%Y-%m-%d %H%M%S", tz = 'UTC')  

  x = db |>
    dplyr::group_by(.data$variable)
  groups = dplyr::group_keys(x) |> dplyr::pull(1)
  x = dplyr::group_map(x,
      function(tbl, key){
        ff = compose_filename(tbl, path)
        if (!is.null(depth)){
           s = stars::read_stars(ff,
                                 along = list(depth = unique(tbl$numdepth),
                                              time = unique(tbl$datetime)))
        } else {
          s = stars::read_stars(ff,
                                along = list(time = tbl$ttime)) 
        }
        s
      },
      .keep = TRUE) |>
  bind_stars() |>
  rlang::set_names(groups)
  
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

