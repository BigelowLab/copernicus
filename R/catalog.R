#' Fetch catalog
#' 
#' @export
#' @param filename chr the name of the file to download
#' @param app chr the name of the app to run
#' @return catalog list
fetch_dataset_catalog = function(filename = copernicus_path("catalogs/all_products_and_datasets.json"),
                         app = get_copernicus_app()){
  cmd = sprintf("describe --return-fields datasets > %s", filename)
  path = dirname(filename)
  if (!dir.exists(path)) ok = dir.create(path, recursive = TRUE)
  ok = system2(app, cmd)
  cat("dataset catalog downloaded: ", ok == 0, "\n")
  read_dataset_catalog(filename)
}


#' Unpack a single node into a tibble
#' 
#' @export
#' @param x a single dataset catalog node
#' @return a table of attribute data (short_name, standard_name, vars)
unpack_dataset = function(x = get_dataset_node()){
  
  stopifnot(c("dataset_id", "dataset_name", "versions") %in% names(x))
  
  vars = x$versions[[1]]$parts[[1]]$services[[1]]$variables 
  if (length(vars) > 0){
    v = lapply(vars,
      function(v){
        nms = names(v)
        short_name = if("short_name" %in% nms) v$short_name else ""
        standard_name = if("standard_name" %in% nms) v$standard_name else ""
        units = if("units" %in% nms) v$units else ""
        dplyr::tibble(
          short_name,
          standard_name,
          units)
      }) |>
      dplyr::bind_rows()
  } else {
    v = NULL
  } # vars missing?
  r = dplyr::tibble(dataset_id = x$dataset_id,
                    dataset_name = x$dataset_name,
                    vars = list(v))
 
  return(r)
}

#' Get one dataset catalog node
#' 
#' @export
#' @param x dataset catalog list
#' @param y number or name of the node to index
#' @return a datasetnode (list with id, name and versions elements)
get_dataset_node <- function(x = read_dataset_catalog(), 
                             y = 1){
  x[[y[1]]][[1]][[1]]
}


#' Tabulate dataset metadata
#' 
#' @export
#' @param x a datasets catalog node
#' @return tibble
tabulate_datasets = function(x = read_dataset_catalog()){
  r = lapply(names(x),
             function(nm){
               get_dataset_node(x, nm) |>
                 unpack_dataset()
               }) |>
    dplyr::bind_rows()
}


#' Read the json dataset catalog
#' 
#' @export
#' @param filename chr the path to the file
#' @return a named list of json element
read_dataset_catalog = function(filename = copernicus_path("catalogs/all_products_and_datasets.json"),
                                tabulate = TRUE){
  x = jsonlite::read_json(filename)[['products']]
  names(x) <- sapply(x,
                     function(n){
                       n[[1]][[1]]$dataset_id
                     })
  if (tabulate) x = tabulate_datasets(x)
  return(x)
}

## ----------------dataset(s) above and product(s) below --------------------- ##

unpack_product = function(x){
  if (!all(c("title", "product_id", "datasets") %in% names(x))){
    stop("this doesn't look like a product catalog")
  }
  
  lapply(x$datasets, unpack_dataset) |>
    dplyr::bind_rows() |>
    dplyr::mutate(product_id = x$product_id,
                  title = x$title,
                  .before = 1)
}

#' Tabulate a dataset catalog
#' 
#' @export
#' @param x catalog list
#' @return tibble
tabulate_product_catalog = function(x = read_product_catalog()){
  lapply(x, unpack_product) |>
    dplyr::bind_rows()
}

#' Read the json product catalog
#' 
#' @export
#' @param filename chr the path to the file
#' @return a named list of json element
read_product_catalog = function(filename = copernicus_path("catalogs/all_products.json"),
                                tabulate = TRUE){
  x = jsonlite::read_json(filename)[['products']]
  names(x) <- sapply(x,
                     function(n){
                       n$product_id
                     })
  if (tabulate) x = tabulate_product_catalog(x)
  return(x)
}