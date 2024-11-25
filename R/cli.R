# A function to apply single non-fancy (or fancy) quotes
#
# @param x character string
# @param fancy logical, curly quotes? (TRUE) or plain quotes (FALSE)?
# @return single quoted value of x
squote = function(x, fancy = FALSE){
  on.exit({
    options("useFancyQuotes")
  })
  orig_fancy = options("useFancyQuotes")
  options(useFancyQuotes = fancy)
  sQuote(x)
}


#' Build a CLI subset request 
#' 
#' See \href{https://help.marine.copernicus.eu/en/articles/7972861-copernicus-marine-toolbox-cli-subset#h_a906235d0a}{the docs}
#' 
#' @param dataset_id char, the data set identifier such as 'cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m'
#' @param vars char, a vector of one or more variables such as c("uo", "vo")
#' @param bb \code{\link[sf]{bbox}} or named numeric vector, either a \code{\link[sf]{bbox}} or 
#'    a 4 element named vector with "xmin", "xmax", "ymin" and "ymax" named elements
#' @param time POSIXct, Date or character, start and stop times
#' @param depth numeric of NULL, two element vector of min and max depths
#' @param ofile char, the output filename (default is "./output.nc")
#' @param loglevel char, one of DEBUG,INFO,WARN,ERROR,CRITICAL,QUIET
#' @param extra NULL or character, any other arguments for \code{copernicus-marine subset}
#' @param app char, the name of the application to run (default is "copernicus-marine")
#' @return named 2 element character vector of the app and the args
#' copernicus-marine subset -i cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m -x 5.0 -X 10.0 -y 38.0 -Y 42.0 -z 0. -Z 10. -v uo -v vo -t 2022-01-01 -T 2022-01-15 -o ./copernicus-data -f dataset_subset.nc
build_cli_subset = function(dataset_id = "cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m",
                            vars = product_lut('GLOBAL_ANALYSISFORECAST_PHY_001_024') |>
                              dplyr::filter(datasetid == dataset_id) |>
                              dplyr::pull(.data$variables) |>
                              unlist(),
                            bb = c(xmin = 5, ymin = 38, xmax = 10, ymax = 42),
                            depth = c(0, 10),
                            time = c("2022-01-01", "2022-01-15"),
                            ofile = "~/output.nc",
                            loglevel = 'QUIET',
                            extra = "--overwrite",
                            app = "copernicusmarine"){
  
  args = sprintf("subset -i %s --log-level %s", dataset_id[1], toupper(loglevel))
  if (!is.null(vars)){
    s = paste(paste("-v", vars), collapse = " ")
    args = sprintf("%s %s", args, s)
  }
  if (!is.null(bb)){
    if (!inherits(bb, 'numeric')) bb = as.numeric(bb)
    s = sprintf("-x %0.2f -X %0.2f -y %0.2f -Y %0.2f", bb[['xmin']], bb[['xmax']], bb[["ymin"]], bb[['ymax']])
    args = sprintf("%s %s", args, s)
  }
  if (!is.null(depth)){
    s = sprintf("-z %0.2f -Z %0.2f", depth[1], depth[2])
    args = sprintf("%s %s", args, s)
  }
  if (!is.null(time)){
    time = time_as_string(time)
    s = sprintf('-t "%s" -T "%s"', time[1], time[2])
    args = sprintf("%s %s", args, s)
  }
  
  if (!is.null(extra)) args = sprintf("%s %s", args, extra)
  
  args = sprintf("%s -f %s -o %s", args, squote(basename(ofile)), squote(dirname(ofile))) 
  
  c(app = app, args = args)
}


#' Fetch via copernicus-marine subset
#' 
#' @param ... arguments for \code{\link{build_cli_subset}}
#' @param verbose logical, if true pint the calling sequence excluding credentials
#' @return numeric, 0 for success
download_copernicus_cli_subset = function(..., verbose = FALSE){
  x = build_cli_subset(...)
  if (verbose){
    s = sprintf("%s %s", x[['app']], args = x[['args']])
    cat(s, "\n")
  }
  x[['args']] = sprintf("%s",x[['args']])
  
  system2(x[['app']], args = x[['args']])
}

 
#' Fetch Copernicus data as a list of \code{stars} objects
#'
#' This is a wrapper around \code{\link{download_copernicus_cli_subset}} that
#' hides the details and returns a list of \code{stars} objects.  The downloaded
#' file is deleted.
#'
#' @export
#' @param ofile chr, the temporary (?) outfile
#' @inheritDotParams download_copernicus_cli_subset
#' @param cleanup logical, if TRUE clean up files
#' @return named list of stars objects (organized by variable)
fetch_copernicus_cli_subset = function(ofile = "output.nc", 
                                cleanup = TRUE,
                                ...){
  
  ok = download_copernicus_cli_subset(ofile = ofile, ...)
  if (ok != 0){
    message("download failed for ", basename(ofile))
    return(NULL)
  }
  
  x = unpack_copernicus(ofile)
  if (cleanup) file.remove(ofile)
  x
}