#' Make a path
#'
#' @export
#' @param x character path specification
#' @param recursive logical
#' @param ... other argum,ents for \code{dir.create}
#' @return logical with TRUE for success
make_path <- function(x, recursive = TRUE, ...){

  ok <- dir.exists(x)
  if(!ok) {
    ok <- dir.create(x, recursive = recursive, showWarnings = FALSE, ...)
  }
  ok
}
