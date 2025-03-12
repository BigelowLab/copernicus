#' Compose a file name from a database
#'
#' @export
#' @param x database (tibble), with date, var, depth
#' @param path character, the root path for the file name
#' @param ext character, the file name extension to apply (including dot)
#' @return character vector of file names in form
#'         \code{<path>/YYYY/mmdd/id__datetime_depth_period_variable_treatment.ext}
compose_filename <- function(x, path = ".", ext = ".tif"){
  
  # <path>/YYYY/mmdd/id__datetime_depth_period_variable_treatment.ext
  file.path(path,
            format(x$date, "%Y/%m%d"),
            sprintf("%s_%s_%s_%s_%s%s",
                    format(x$date, "%Y-%m-%d"), 
                    x$period,
                    x$var,
                    x$depth, 
                    x$treatment,
                    ext))
}

#' Decompose a file name into a database
#'
#' @export
#' @param x character, vector of one or more file names
#' @param ext character, the extension to remove (including dot)
#' @return table (tibble) database
decompose_filename = function(x = c("2025-03-17_day_uo_sur_none.tif",
                                      "2019-01-01_day_mlotst_sur_none.tif"),
                                  ext = ".tif"){
  
  # a tidy version of gsub
  global_sub <- function(x, pattern, replacement = ".tif", fixed = TRUE, ...){
    gsub(pattern, replacement, x, fixed = fixed, ...)
  }
  x <- basename(x) |>
    global_sub(pattern = ext, replacement = "") |>
    strsplit(split = "_", fixed = TRUE)
  #1 = date
  #2 = period
  #3 = var
  #4 = depth
  #5 = treatment

  dplyr::tibble(
    date = sapply(x, '[[', 1),
    period = sapply(x, '[[', 2),
    var = sapply(x, '[[', 3),
    depth = sapply(x, '[[', 4),
    treatment = sapply(x, '[[', 5) )
}



#' Decompose a filename into a database
#'
#' @param x character, vector of one or more filenames
#' @param ext character, the extension to remove (including dot)
#' @return table (tibble) database
decompose_filename_pre_v2 = function(x = c("2025-03-17_day_uo_sur_none.tif",
                                    "2019-01-01_day_mlotst_sur_none.tif"),
                              ext = ".tif"){
  
  datetime = function(x = c("2022-01-15T000000", "2022-01-16T123456")){
    list(date = as.Date(substring(x, 1,10), format = "%Y-%m-%d"),
         time = substring(x, 12))
  }
  # a tidy version of gsub
  global_sub <- function(x, pattern, replacement = ".tif", fixed = TRUE, ...){
    gsub(pattern, replacement, x, fixed = fixed, ...)
  }
  x <- basename(x) |>
    global_sub(pattern = ext, replacement = "") |>
    strsplit(split = "__", fixed = TRUE)
  y = sapply(x, '[[', 2) |>
    strsplit(split = "_", fixed = TRUE)
  #1 = datetime
  #2 = depth
  #3 = period
  #4 = variable
  #5 = treatement
  
  dt = datetime(sapply(y, '[[', 1))
  dplyr::tibble(
    id = sapply(x, '[[', 1),
    date = dt$date,
    time = dt$time,
    depth = sapply(y, '[[', 2),
    period = sapply(y, '[[', 3),
    variable = sapply(y, '[[', 4),
    treatment = sapply(y, '[[', 5) )
}

#' Compose a filename from a database
#'
#' @param x database (tibble), with date, var, depth
#' @param path character, the root path for the filename
#' @param ext character, the filename extension to apply (with dot)
#' @return character vector of filenames in form
#'         \code{<path>/YYYY/mmdd/YYYY-mm-dd_var_depth.tif}
compose_filename_v0.01 <- function(x, path = ".", ext = ".tif"){
  yyyymmdd <- format(x$date, "%Y/%m%d")
  # <path>/YYYY/mmdd/YYYY-mm-dd_trt_param.tif
  file.path(path,
            format(x$date, "%Y/%m%d"),
            sprintf("%s_%s_%s%s",
                    format(x$date, "%Y-%m-%d"),
                    x$var,
                    x$depth,
                    ext))
}
#' Decompose a filename into a database
#'
#' @param x character, vector of one or more filenames
#' @param ext character, the extension to remove (including dot)
#' @return table (tibble) database
decompose_filename_v0.01 <- function(x = "2021-03-20_zos_sur.tif",
                               ext = ".tif"){

  
  # a tidy version of gsub
  global_sub <- function(x, pattern, replacement = ".tif", fixed = TRUE, ...){
    gsub(pattern, replacement, x, fixed = fixed, ...)
  }
  x <- basename(x) |>
    global_sub(pattern = ext, replacement = "") |>
    strsplit(split = "_", fixed = TRUE)
  # <path>/YYYY/mmdd/YYYY-mm-dd_trt_param.tif
  dplyr::tibble(
    date = as.Date(sapply(x, '[[', 1), format = "%Y-%m-%d"),
    var = sapply(x, '[[', 2),
    depth = sapply(x, '[[', 3))
}

#' Construct a database tibble give a data path
#'
#' @export
#' @param path character the directory to catalog
#' @param pattern character, the filename pattern (as glob) to search for
#' @param save_db logical, if TRUE save the database via [write_database]
#' @param ... other arguments for \code{\link{decompose_filename}}
#' @return tibble database
build_database <- function(path, pattern = "*.tif", 
                           save_db = FALSE, ...){
  if (missing(path)) stop("path is required")
  db = list.files(path[1], pattern = utils::glob2rx(pattern),
             recursive = TRUE, full.names = TRUE) |>
    decompose_filename(...)
  if (save_db) db = write_database(db, path)
  return(db)
}


#' Read a file-list database
#'
#' @export
#' @param path character the directory with the database
#' @param filename character, optional filename
#' @return a tibble
read_database <- function(path,
                          filename = "database.csv.gz"){
  if (missing(path)) stop("path is required")
  filepath <- file.path(path[1], filename[1])
  stopifnot(file.exists(filepath))
  # date var depth
  suppressMessages(readr::read_csv(filepath, col_types = 'Dcccc'))
}

#' Write the file-list database
#'
#' We save only date (YYYY-mm-dd), param, trt (treatment) and src (source). If you
#' have added other variables to the database they will be dropped in the saved
#' file.
#'
#' @export
#' @param x the tibble or data.frame database
#' @param path character the directory to where the database should reside
#' @param filename character, optional filename
#' @return the input tibble (even if saved version has columns dropped)
write_database <- function(x, path,
                           filename = "database.csv.gz"){
  if (missing(path)) stop("path is required")
  filepath <- file.path(path[1], filename[1])
  # date var depth
  dummy <- x |>
    #dplyr::select(.data$date, .data$var, .data$depth) |>
    readr::write_csv(filepath)
  invisible(x)
}

#' Append one or more rows to a database.
#'
#' The databases must have identical column classes and names.
#'
#' @export
#' @param db tibble, the database to append to
#' @param x tibble, the new data to append.  If this has no rows then the
#'  original database is returned
#' @param rm_dups logical, if TRUE remove duplicates from combined databases.
#'  If x has no rows then this is ignored.
#' @return the updated database tibble
append_database <- function(db, x, rm_dups = TRUE){

  if (!identical(colnames(db), colnames(x)))
    stop("x column names must be identical to db column names\n")

  if (!identical(sapply(db, class), sapply(x, class)))
    stop("x column classes must be identical to db column classes\n")

  if (nrow(x) > 0){
    db <- dplyr::bind_rows(db, x)
    if (rm_dups) db <- dplyr::distinct(db)
  }

  db
}


#' Given a database (days, 8DR or month), determine the times
#' that are missing between the first and last records
#' 
#' @export
#' @param x a database - typically filtered to just a single period
#' @param by chr, unit of time used for creating sequence to match against
#' @return Date dates that seem to be missing
missing_records = function(x, 
                           by = dplyr::slice(x,1) |> 
                             dplyr::pull(dplyr::all_of("period"))){
  dr = range(x$date)
  dd = seq(from = dr[1], to = dr[2], by = by)
  dd[!(dd %in% x$date)]
}