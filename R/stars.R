#' Read a ncdf object into a list of stars objects, possibly grouped by
#' dimensional dependence.
#' 
#' @export
#' @param filename str, the name of the file to read
#' @param group logical, if TRUE read variables grouped by dimensional dependence
#'   if FALSE then each variable is read separately
#' @return list of stars objects
read_stars_list = function(filename, group = TRUE){
  
  v = list_vardims(filename)
  
  if (group){
    v = v |>
      dplyr::group_by(.data$dims)
    r = v |>
      dplyr::group_map(
        function(grp, key){
           stars::read_stars(filename, sub = grp$name)
        }) |>
      rlang::set_names(dplyr::group_keys(v) |> dplyr::pull(1))
  } else {
    r = v |>
      dplyr::rowwise() |>
      dplyr::group_map(
        function(row, key){
          stars::read_stars(filename, sub = row$name)
        }
      ) |>
      rlang::set_names(v$name)
  }
  return(r)
}