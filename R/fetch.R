#' Retrieve a stars array of Copernicus data
#' 
#' @export
#' @param use char, download method one of 'cli' or 'script' (deprecated)
#' @param form str, one of "stars" or "filename" to return a stars object or the filename
#'   If "filename" then no attempt is made to read the downloaded file and `cleanup` is ignored.
#'   If "list" then read the file into a list of stars objects where variables are grouped
#'   by dimensional dependence.
#' @param bind logical, if TRUE bind the elements of the returned into a single 
#'   multi-attribute stars object. Ignored if `form` is not "stars"
#' @inheritDotParams download_copernicus_cli_subset
fetch_copernicus = function(use = c("cli", "script")[1], 
                            bind = TRUE,
                            form = c("stars", "filename", "list")[1],
                            ...){
  use = tolower(use[1])
  x = switch(use,
         'cli' = try(fetch_copernicus_cli_subset(form = form[1], ...)),
         stop("only cli downloads are supported")) 
  if (inherits(x, "try-error")) return(NULL)
  if (!is.null(x) && !inherits(x, 'stars') && bind && tolower(form[1]) == "stars"){
    x = bind_stars(x)
  }
  x
}


