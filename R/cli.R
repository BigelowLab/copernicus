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
#' @export
#' @param dataset_id char, the data set identifier such as 'cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m'
#' @param product chr the product family such as "global-analysis-forecast-phy-001-024"
#' @param vars char, a vector of one or more variables such as c("uo", "vo")
#' @param bb \code{\link[sf]{bbox}} or named numeric vector, either a \code{\link[sf]{bbox}} or 
#'    a 4 element named vector with "xmin", "xmax", "ymin" and "ymax" named elements
#' @param time POSIXct, Date or character, start and stop times
#' @param depth numeric of NULL, two element vector of min and max depths
#' @param ofile char, the output filename (default is "./output.nc")
#' @param extra NULL or character, any other arguments for \code{copernicusmarine subset}
#' @param app char, the name of the application to run (default is "copernicusmarine")
#' @param dry_run logical, if TRUE enter at DEBUG_LEVEL mode and just do a dry run (no data download)
#' @param log_level chr, one of DEBUG | INFO | WARN | ERROR | CRITICAL | QUIET
#' @return named 2 element character vector of the app and the args
#' copernicusmarine subset -i cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m -x 5.0 -X 10.0 -y 38.0 -Y 42.0 -z 0. -Z 10. -v uo -v vo -t 2022-01-01 -T 2022-01-15 -o ./copernicus-data -f dataset_subset.nc
build_cli_subset = function(dataset_id = "cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m",
                            product = "GLOBAL_ANALYSISFORECAST_PHY_001_024",
                            vars = product_lut(product[1]) |>
                              dplyr::filter(.data$dataset_id == dataset_id) |>
                              dplyr::pull(dplyr::all_of("short_name")) |>
                              unlist(),
                            bb = c(xmin = 5, ymin = 38, xmax = 10, ymax = 42),
                            depth = c(0, 1),
                            time = c("2022-01-01", "2022-01-15"),
                            ofile = sprintf("%s_%s_%s.nc",
                                            product, dataset_id, 
                                            format(as.Date(time[1]), "%Y-%m-%d")),
                            extra = "--overwrite",
                            app = get_copernicus_app(),
                            dry_run = FALSE,
                            log_level = ifelse(dry_run, "DEBUG", "ERROR") ){

  if (FALSE){
    dataset_id = "cmems_mod_glo_phy_my_0.083deg_P1D-m"
    product = "GLOBAL_MULTIYEAR_PHY_001_030"
    vars = product_lut(product[1]) |>
      dplyr::filter(.data$dataset_id == dataset_id) |>
      dplyr::pull(dplyr::all_of("short_name")) |>
      unlist()
    time = structure(c(8401, 8401), class = "Date")
    ofile = sprintf("%s_%s_%s.nc",
                    product, dataset_id, 
                    format(time[1], "%Y-%m-%d"))
    extra = "--overwrite"
    app = get_copernicus_app()
    log_level = "ERROR"
    dry_run = FALSE
  }
  
  args = sprintf("subset -i %s --log-level %s", dataset_id[1], toupper(log_level))
  
  if (!is.null(vars)){
    s = paste(paste("-v", vars), collapse = " ")
    args = sprintf("%s %s", args, s)
  }
  
  if (dry_run) args = paste(args, "--dry-run")
  
  if (!is.null(bb)){
    if (!inherits(bb, 'numeric')) bb = as.numeric(bb)
    s = sprintf("-x %0.2f -X %0.2f -y %0.2f -Y %0.2f", bb[['xmin']], bb[['xmax']], bb[["ymin"]], bb[['ymax']])
    args = sprintf("%s %s", args, s)
  }
  # if depth is NULL or both elements are NA then skip
  if (!is.null(depth) & (!all(is.na(depth[1])))){
    s = sprintf("-z %0.2f -Z %0.2f", as.numeric(depth[1]), as.numeric(depth[2]))
    args = sprintf("%s %s", args, s)
  }
  if (!is.null(time)){
    if (!inherits(time, "character")) {
      time = format(time, "%Y-%m-%dT%H:%M:%S")
    } else {
      time = as.Date(time, format = "%Y-%m-%d") |>
        format("%Y-%m-%dT%H:%M:%S")
    }
    s = sprintf('-t %s -T %s', time[1], time[2])
    args = sprintf("%s %s", args, s)
  }
  
  
  
  if (!is.null(extra)) args = sprintf("%s %s", args, extra)
  
  args = sprintf("%s -f %s -o %s", args, squote(basename(ofile)), squote(dirname(ofile))) 
  
  c(app = app, args = args)
}


#' Fetch via copernicusmarine subset
#' 
#' @export
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
#' @return named list of stars objects (organized by variable) or NULL
fetch_copernicus_cli_subset = function(ofile = "output.nc", 
                                cleanup = TRUE,
                                ...){
  
  ok = try(download_copernicus_cli_subset(ofile = ofile, ...))
  if (inherits(ok, "try-error")) return(NULL)
  if (ok != 0){
    message("download failed for ", basename(ofile))
    return(NULL)
  }
  # read in as stars
  x = unpack_copernicus(ofile)
  if (cleanup) file.remove(ofile)
  x
}