#' Retrieve the copernicus path
#'
#' @export
#' @param ... further arguments for \code{file.path()}
#' @param root the root path
#' @return character path description
copernicus_path <- function(...,
  root = "/mnt/ecocast/coredata/copernicus") {

  file.path(root, ...)
}

#' Given a path - make it if it doesn't exist
#'
#' @export
#' @param path character, the path to check and/or create
#' @param recursive logical, create paths recursively?
#' @param ... other arguments for \code{\link[base]{dir.create}}
#' @return logical, TRUE if the path exists or is created
make_path <- function(path, recursive = TRUE, ...){
  ok <- dir.exists(path[1])
  if (!ok){
    ok <- dir.create(path, recursive = recursive, ...)
  }
  ok
}
