#' Retrieve a stars array of Copernicus data
#' 
#' @export
#' @param use char, download method one of 'cli' or 'script' (deprecated)
#' @inheritDotParams download_copernicus_cli
fetch_copernicus = function(use = c("cli", "script")[1], 
                            ...){
  
  use = tolower(use[1])
  switch(use,
         'cli' = fetch_copernicus_cli(...),
         'script' = fetch_copernicus_script(...)) 
}