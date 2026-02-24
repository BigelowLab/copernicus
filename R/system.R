#' Detect the operating system
#' 
#' @export
#' @return chr one of "linux", "darwin" or "windows"
detect_os = function(){
  sysname = Sys.info()[['sysname']]
  tolower(sysname)
}

#' Run either system() or system2() depending upon the host platform.
#' 
#' We have encountered trouble using system2() on darwin/macos
#'
#' @export
#' @param args chr a single character string of arguments for the app 
#' @param app chr the path and name of the copernicusmarine app
#' @param verbose logical, if TRUE echo the command before issuing it
#' @param ... arguments passed to either `system` or `system2`
#' @return num, 0 if success, non-zero otherwise
system_command = function(args, 
                          app = get_copernicus_app(),
                          verbose = FALSE,
                          ...){
  
  if (verbose){
    cat("CMD:", app, args, "\n")
  }
  
  switch(detect_os(),
         "darwin" = {
           cmd = paste(app, args)
           system(cmd, ...)
         },
         system2(app, args, ...))
  
}
