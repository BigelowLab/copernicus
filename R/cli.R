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
#' @param extra NULL or character, any other arguments for \code{copernicus-marine subset}
#' @param app char, the name of the application to run (default is "copernicus-marine")
#' @return named 2 element character vector of the app and the args
#' copernicus-marine subset -i cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m -x 5.0 -X 10.0 -y 38.0 -Y 42.0 -z 0. -Z 10. -v uo -v vo -t 2022-01-01 -T 2022-01-15 -o ./copernicus-data -f dataset_subset.nc
build_cli_subset = function(dataset_id = "cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m",
                            vars = c("uo","vo"),
                            bb = c(xmin = 5, ymin = 38, xmax = 10, ymax = 42),
                            depth = c(0, 10),
                            time = c("2022-01-01", "2022-01-15"),
                            ofile = "output.nc",
                            extra = "--force-download  --overwrite",
                            app = "copernicus-marine"){
  
  args = sprintf("subset -i %s", dataset_id[1])
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
    if (!inherits(time, "character")) {
      time = format(time, "%Y-%m-%dT%H:%M:%S")
    } else {
      time = as.Date(time, format = "%Y-%m-%d") |>
        format("%Y-%m-%dT%H:%M:%S")
    }
    s = sprintf('-t "%s" -T "%s"', time[1], time[2])
    args = sprintf("%s %s", args, s)
  }
  
  if (!is.null(extra)) args = sprintf("%s %s", args, extra)
  
  args = sprintf("%s -f %s -o %s", args, basename(ofile), dirname(ofile)) 
  
  c(app = app, args = args)
}


#' Fetch via copernicus-marine subset
#' 
#' @param ... arguments for \code{\link{build_cli_subset}}
#' @param verbose logical, if true pint the calling sequence excluding credentials
#' @param credentials two element named character vector of \code{username} and \code{password}
#' @return numeric, 0 for success
download_copernicus_cli = function(..., verbose = FALSE, credentials = get_credentials()){
  x = build_cli_subset(...)
  if (verbose){
    s = sprintf("%s %s", x[['app']], args = x[['args']])
    cat(s, "\n")
  }
  x[['args']] = sprintf("%s --username %s --password %s",x[['args']], 
                      credentials[['username']],
                      credentials[['password']])
  
  system2(x[['app']], args = x[['args']])
}

 
#' Fetch Copernicus data as a list of \code{stars} objects
#'
#' This is a wrapper around \code{\link{download_copernicus_cli}} that
#' hides the details and returns a list of \code{stars} objects.  The downloaded
#' file is deleted.
#'
#' @export
#' @param ofile chr, the temporary (?) outfile
#' @inheritDotParams download_copernicus_cli
#' @param cleanup logical, if TRUE clean up files
#' @return named list of stars objects (organized by variable)
fetch_copernicus_cli = function(ofile = "output.nc", 
                                cleanup = TRUE,
                                ...){
  
  ok = download_copernicus_cli(ofile = ofile, ...)
  if (ok != 0){
    message("download failed for", basename(ofile))
    return(NULL)
  }
  
  x = unpack_copernicus(ofile)
  if (cleanup) file.remove(ofile)
  x
}