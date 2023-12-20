#' Retrieve a stars array of Copernicus data
#' 
#' @export
#' @param use char, download method one of 'cli' or 'script' (deprecated)
#' @param bind logical, if TRUE bind the elements of the returned into a single 
#'   multi-attribute stars object.
#' @inheritDotParams download_copernicus_cli_subset
fetch_copernicus = function(use = c("cli", "script")[1], 
                            bind = TRUE,
                            ...){
  use = tolower(use[1])
  x = switch(use,
         'cli' = fetch_copernicus_cli_subset(...),
         'script' = fetch_copernicus_script(...)) 
  if (!is.null(x) && !inherits(x, 'stars') && bind){
    x = bind_stars(x)
  }
  x
}