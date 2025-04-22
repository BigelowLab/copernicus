#' Read shell script into a character array
#'
#' @export
#' @param name character, the name of the script file
#' @param path character, the path to the script
#' @return named character vector with 'app' and 'param'
read_script <- function(name = "cmems_mod_glo_phy",
                        path = system.file("scripts", package = "copernicus")){
  filename <- file.path(path[1], name[1])
  x <- readLines(filename)
  ix <- regexpr("\\s", x)
  c("app" = substring(x, 1, ix-1),
    "param" = substring(x, ix+1, nchar(x)))
}

#' Populate a script
#'
#' @export
#' @param template the name of the script template
#' @param bb 4 element bounding box [west, east, south, north]
#' @param dates 2 element Date or Date-castable, [start, stop]
#' @param times 2 element character vector, times (default is 12:00:00)
#' @param depths 2 element numeric,  depth [min, max]
#' @param variables character vector, variable names
#' @param product_id char the product id ala 'cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m'
#' @param out_dir character, output directory
#' @param out_name character, output filename
#' @param credentials character or NULL, (if NULL get from options)
#' @param ... ignored
#' @return 2 element character vector of 'app' and 'param'
populate_script <- function(template = read_script(),
                            bb = c(-77, -42.5, 36.5, 56.7),
                            dates = Sys.Date() + c(-2, -1),
                            times = c("01:00:00", "23:00:00"),
                            depths = c(0.493, 0.4942),
                            product_id = "foo",
                            variables = c("bottomT", "mlotst", "siconc", "sithick",
                                         "so", "thetao", "uo",
                                         "usi", "vo", "vsi", "zos"),
                            out_dir = copernicus_path("tmp"),
                            out_name = sprintf("copernicus_%s.nc",
                                               format(Sys.Date(), "%Y-%m-%d")),
                            credentials = NULL,
                            ...){
  
  if (is.null(credentials)) credentials = get_credentials(parse = TRUE)
  if (is.null(credentials)) stop("credentials must be provided")
  if (!inherits(dates, "Date")) dates <- as.Date(dates)
  dates <- format(dates, '%Y-%m-%d')
  dates <- paste(dates, times)
  variables <-paste(paste("--variable", variables), collapse = " ")
  r <- c(
    LON_MIN = bb[1],
    LON_MAX = bb[2],
    LAT_MIN = bb[3],
    LAT_MAX = bb[4],
    DATE_MIN = dates[1],
    DATE_MAX = dates[2],
    DEPTH_MIN = as.character(depths[1]),
    DEPTH_MAX = as.character(depths[2]),
    VARIABLES = variables,
    PRODUCT_ID = product_id,
    OUT_DIR = out_dir[1],
    OUT_NAME = out_name[1],
    USERNAME = credentials[['username']],
    PASSWORD = credentials[['password']])

  for (n in names(r)){
    flag <- paste0("$", n)
    template[['param']] <- gsub(flag, r[[n]], template[['param']], fixed = TRUE)
  }
  template
}


#' Fetch (download) copernicus data
#'
#' @export
#' @param x charcater, a two element script vector comprised of
#' \itemize{
#' \item{app the name of the application to call, either python or python3}
#' \item{param the parameter (argument) vector fully populated}
#' }
#' @return integer with 0 for success
download_copernicus_script <- function(x = populate_script()){
  
  #.Deprecated("download_copernicus_cli", 
  #            package="copernicus", 
  #            old = as.character(sys.call(sys.parent()))[1L])
  
  system2(x[['app']], x[['param']])
}


#' Fetch Copernicus data as a list of \code{stars} objects
#'
#' This is a wrapper around \code{\link{download_copernicus_script}} that
#' hides the details and returns a list of \code{stars} objects.  The downloaded
#' file is deleted.
#'
#' @export
#' @param script character, the name of the script to use
#' @param date Date class or castable as Date
#' @param out_path character, the temporary path to store the downloaded file
#' @param cleanup logical, if TRUE clean up files
#' @param ... further arguments for \code{\link{populate_script}}
#' @return named list of stars objects (organized by variable)
fetch_copernicus_script <- function(script = "cmems_mod_glo_phy",
                                    date = Sys.Date(),
                                    out_path = tempfile(pattern= 'copernicus',
                                                        tmpdir = tempdir(),
                                                        fileext = ".nc"),
                                    cleanup = TRUE,
                                    ...){
  
  # .Deprecated("fetch_copernicus(use = 'cli', ...)", 
  #             package="copernicus", 
  #             "please select another value for use",
  #             old = as.character(sys.call(sys.parent()))[1L])
  
  if (FALSE){
    script = "cmems_mod_glo_phy"
    date = Sys.Date()
    out_path = tempfile(pattern= 'copernicus',
                        tmpdir = tempdir(),
                        fileext = ".nc")
    cleanup = TRUE
    product_id = 'cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m'
    variables = c("vo")
    
    ok <- read_script(name = script) |>
      populate_script(dates = date,
                      out_dir = dirname(out_path[1]),
                      out_name = basename(out_path[1]),
                      product_id = product_id,
                      variables = variables) |>
      download_copernicus_script()
    
    
  }
  
  ok <- read_script(name = script) |>
    populate_script(dates = date,
                    out_dir = dirname(out_path[1]),
                    out_name = basename(out_path[1]),
                    ...) |>
    download_copernicus_script()
  
  if (ok != 0){
    warning("unable to download copernicus data to", out_path[1])
    return(NULL)
  }
  ss <- stars::read_stars(out_path[1])
  if (cleanup){
    ok <- file.remove(out_path)
    if (!ok) warning("unable to remove file:", out_path[1])
  }
  ss
}


