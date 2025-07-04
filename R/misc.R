#' Convert a time to string
#' 
#' @export
#' @param x char, Date or POSIXt class object
#' @return the input as character
time_as_string = function(x){
  if (inherits(x, "Date")){
    x = format(x, "%Y-%m-%d")
  } else if (inherits(x, "POSIXt")){
    x = format(x, "%Y-%m-%dT%H:%M:%S", tz = 'UTC')
  }
  x
}

#' Bind a list of stars objects into a multi-attribute stars object
#' 
#' @export
#' @param x list of stars objects
#' @param tolerance num, see [stars::c.stars]
#' @return a single multi-attribute stars object
bind_stars = function(x, tolerance = 1e-6){
  do.call(c, append(x, list(along = NA_integer_, tolerance = tolerance)))
}
#' Guess the time interval
#' 
#' @export
#' @param x ncdf4 object or stars object
#' @param dimname char the time-dependent dimension name
#' @return character string such as "day", "mon", "year" or "secs"
guess_period = function(x, dimname = "time"){
  
  dm = dimname[1]
  
  if (inherits(x, 'stars')){
    delta = stars::st_get_dimension_values(x, dm)
    if (is.null(delta)) {
      return("unk")
    } else {
      delta = diff(delta)
    }
  } else {
    delta = diff(x$dim[[dm]]$vals)
  }
  r = switch(units(delta),
             "hours" = "hour",
             'days' = "day",
             'months' = 'month',
             "years" = 'year',
             "secs" = "sec",
             "unk")
  r
}


#' Generate one or more file names for the data
#' 
#' File names have the form of "id__datetime_depth_period_variable_treatment.ext"
#' Note the double underscore which permits parsing of the id if needed. Multiples
#' are ordered by first time, then variable and finally depth Presumably, period,
#' if known, is repeated
#' 
#' The pattern is datasetid__time_depth_period_var_treatment.ext
#'
#' @export
#' @param x ncdf4 object or stars object
#' @param id character, the product or dataset identifier
#' @param depth, if NULL guess the depth, otherwise use the specified depth
#' @param depth_signif numeric, passed to \code{\link[base]{signif}} for rounding.
#' @param period char, the period description, guessed if not provided
#' @param treatment char the treatment description
#' @param ext char, the file extension of NULL to skip
generate_filename = function(x,
                             id = "copernicus",
                             depth = NULL,
                             depth_signif = 4,
                             period = guess_period(x),
                             treatment = "raw",
                             ext = "tif"){
  if (inherits(x, 'ncdf4')){
    dnames = names(x$dim)
    if ("time" %in% dnames) {
      time = get_time(x) |>
        format("%Y-%m-%dT%H%M%S")
      if (inherits(time, "Date")){
        time = format(time, "%Y-%m-%dT000000")
      } else {
        time = format(time, "%Y-%m-%dT%H%M%S", tz = 'UTC')
      }
    } else {
      time = NA_character_
    }
    if (!is.null(depth)){
      depth = signif(depth, depth_signif)
    } else if ("depth" %in% dnames){
      depth = signif(get_depth(x), depth_signif)
    } else {
      depth = NA_character_
    }
    varnames = names(x$var)
    
  } else { # ncdf
    
    dnames = stars::st_dimensions(x) |>
      names()
    if ("time" %in% dnames) {
      time = stars::st_get_dimension_values(x, "time")
      if (inherits(time, "Date")){
        time = format(time, "%Y-%m-%dT000000")
      } else {
        time = format(time, "%Y-%m-%dT%H%M%S", tz = 'UTC')
      }
    } else {
      time = NA_character_
    }
    
    if (!is.null(depth)){
      depth = signif(depth, depth_signif)
    } else if ("depth" %in% dnames){
      depth = stars::st_get_dimension_values(x, "depth") |>
        signif(depth_signif)
    } else {
      depth = NA_character_
    }
    varnames = names(x)
  } # stars
  
  
  # "id__datetime_depth_period_variable_treatment.ext"
  # for each depth
  #   for each time
  #      sprintf
  # unlist
  pattern = "%s__%s_%s_%s_%s_%s.%s"
  lapply(depth,
    function(this_depth){
      lapply(time, 
             function(this_time){
               sprintf(pattern,
                       id,
                       this_time,
                       this_depth,
                       period,
                       varnames,
                       treatment,
                       ext)
             })
    }) |>
  unlist()
}
