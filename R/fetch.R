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
         stop("only cli downloads are supported")) 
  if (!is.null(x) && !inherits(x, 'stars') && bind){
    x = bind_stars(x)
  }
  x
}

#' A convenience tool for fetching a product suite on a given day.
#' 
#' This only works for known products/datasets.  Unknowns will generate a
#' warning and return NULL. For each dataset only a single depth layer is 
#' returned. 
#' 
#' @export
#' @param p table of product info to be grouped by `dataset_id`
#' @param x Date (or YYYY-mm-dd string)
#' @param bb bounding box or somehting from which a bounding box can be found.
#' @param ... other arguments for [fetch_copernicus_cli_subset]
#' @return list of stars objects (one for each dataset) possibly with NULLs for unknown datasets
fetch_product_by_day = function(p = product_lut() |>
                                  dplyr::filter(fetch == "yes",
                                                product_id == .data$product_id[1]),
                                x = Sys.Date()-7,
                                bb = c(xmin = -180, ymin = -90, 
                                       xmax = 180, ymax = 90) |>
                                  sf::st_bbox(crs = 4326),
                                ...){
  dates = c(x[1], x[length(x)])

  p = p |>
    dplyr::group_by(.data$dataset_id)
  
  p |>
    group_map(
      function(tbl, key){
        switch(key$dataset_id,
               "cmems_mod_glo_phy_anfc_0.083deg_P1D-m" = {
                 fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = NULL,
                                             ...)
               },
               "cmems_mod_glo_phy_anfc_0.083deg-sst-anomaly_P1D-m" = {
                 s = fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = NULL,
                                             ...)
                 if (!is.null(s)) s = s |> rlang::set_names("sstanom")
                 s
               },
               "cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m" = {
                 s = fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = c(tbl$mindepth[1],tbl$maxdepth[1]),
                                             ...) 
                 if (!is.null(s)) s = s |> dplyr::slice("depth", 1)
                 s
               },
               "cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m" = {
                 s = fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = c(tbl$mindepth[1],tbl$maxdepth[1]),
                                             ...)
                 if (!is.null(s)) s = s |> dplyr::slice("depth", 1)
                 s
               },
               "cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m" = {
                 s = fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = c(tbl$mindepth[1],tbl$maxdepth[1]),
                                             ...)
                 if (!is.null(s)) s = s |> dplyr::slice("depth", 1)
                 s
               },
               "cmems_mod_glo_phy-wcur_anfc_0.083deg_P1D-m" = {
                 s = fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = c(tbl$mindepth[1],tbl$maxdepth[1]),
                                             ...)
                 if (!is.null(s)) s = s |> dplyr::slice("depth", 1)
                 s
               },
               "cmems_mod_glo_phy_my_0.083deg_P1D-m" = {
                 fetch_copernicus_cli_subset(dataset_id = key$dataset_id,
                                             product = tbl$product_id[1],
                                             vars = tbl$short_name,
                                             time = dates,
                                             bb = bb,
                                             depth = NULL,
                                             ...)
               },
               {
                 warning("dataset_id not known, contact developer:", key$dataset_id)
                 NULL
               })
      }) |>
    rlang::set_names(dplyr::group_data(p) |> pull(1))
}
