#' Read a product LUT
#' 
#' @export
#' @param productid cahr, the product indentifier
#' @return tibble
product_lut = function(productid = 'GLOBAL_ANALYSISFORECAST_PHY_001_024'){
  
  filename = system.file(file.path("lut", paste0(productid, ".csv")), package = "copernicus")
  readr::read_csv(filename, show_col_types = FALSE) |>
    dplyr::mutate(variables = strsplit(.data$variables, "+", fixed = TRUE),
                  unit = strsplit(.data$unit, "+", fixed = TRUE))
}



#' Given a NCDF object (or path to one) create a variable lookup table (LUT)
#' 
#' @export
#' @param x ncdf4 object or path to one, if the latter we will open and then close it
#' @return tibble LUT of \code{name}, \code{longname} and \code{units}
create_lut <- function(x){
  
  close_me = FALSE
  if (!inherits(x, 'ncdf4')){
    x = ncdf4::nc_open(x)
    close_me = TRUE
  }
  
  # name,longname,units
  name <- names(x$var)
  longname = sapply(name,
        function(nm) x$var[[nm]]$longname)
  units = sapply(name,
                 function(nm) x$var[[nm]]$units)
  if (close_me) ncdf4::nc_close(x)
  
  dplyr::tibble(
    name = name,
    longname = unname(longname),
    units = unname(units))
}

#' Read a regional LUT ala ("nwa_lut.csv")
#' 
#' @export
#' @param region char the name of the region
#' @param path char the path to the LUT
#' @return tibble with "name", "longname" and "units"
read_region_lut <- function(region = "nwa",
                            path = copernicus_path("lut")){
  
  filename = file.path(path, paste0(region[1], "_lut.csv"))
  if (!file.exists(filename)) stop("file not found:", basename(filename))
  readr::read_csv(filename, col_types = "cccc")
}



#' Merge one or more LUTs together
#' 
#' @export
#' @param service char the name of the service
#' @param path char, the path to the LUTs
#' @return tibble or combined product luts for this service
#'   with "name", "longname" and "units"
read_service_lut <- function(service = "global_analysisforecast_phy_001_024",
                             path = copernicus_path("lut")){
  fullpath = file.path(path, service[1])
  ff <- list.files(fullpath, full.names = TRUE)
  if (length(ff) == 0) stop("no files found in path:", fullpath )  
  lapply(ff,
    function(f){
      readr::read_csv(f, col_types = "ccc") |>
        dplyr::mutate(product_id = basename(f), .before = 1)
      }) |>
    dplyr::bind_rows()
}