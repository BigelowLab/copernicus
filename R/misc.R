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

#' Bind a list of stars objectys into a multi-attribute stars object
#' 
#' @export
#' @param x list of stars objects
#' @return a single multi-attribute stars object
bind_stars = function(x){
  do.call(c, append(x, list(along = NA_integer_)))
}

#' Guess the time interval
#' 
#' @export
#' @param x ncdf4 object or stars object
#' @param dimname char the time-dependent dimension name
#' @return character string such as "day", "mon", "year" or NA
guess_period = function(x, dimname = "time"){
  
  r = NA_character_
  dm = dimname[1]
  
  if (inherits(x, 'stars')){
    d = stars::st_dimensions(x)
    if (is.null(d[[dm]])) return(r)
    delta = d[[dm]]$delta
    if (is.na(delta)) return(r)
  } else {
    delta = diff(x$dim$depth$vals)
  }
  r = switch(units(delta),
             "hours" = "hour",
             'days' = "day",
             'months' = 'month',
             "years" = 'years',
             stop("unit not known:", units(d)))
  r
}


#' Generate one or more filenames for the data
#' 
#' Filenames have the form of "id__datetime_depth_period_variable_treatment.ext"
#' Note the double underscore which permits parsing of the id if needed. Multiples
#' are ordered by first time, then variable and finally depth Presumably, period,
#' if known, is repeated
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


#' Archive a stars object to a database
#' 
#' @export
#' @param x stars object
#' @param path char, the data path
#' @param ... arguments for \code{\link{generate_filename}}
#' @return tabular database as a tibble
archive_copernicus = function(x,
                              path = ".",
                              ...){
  
  ff = generate_filename(x, ...)
  db = decompose_filename(ff)
  ff = compose_filename(db, path)
  # for each time, variable, depth order in filename
  d = dim(x)
  i = 1
  n = length(x)
  for (idepth in seq_len(d[['depth']])){
    for (itime in seq_len(d[['time']])){
      for (v in (seq_len(n))){
        if (!dir.exists(dirname(ff[i+v]))) dir.create(dirname(ff[i+v]),
                                                      recursive = TRUE)
        stars::write_stars(x[v,,,idepth,itime, drop = TRUE], ff[i+v-1])
      }
      i = i + n # advance the count
    } # iyear
  } # idepth
  
  db
  
}