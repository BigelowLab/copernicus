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
