#' Fetch the description for a dataset
#' 
#' @export
#' @param dataset_id chr, the dataset to describe
#' @param app chr, the `copernicusmarine` app
#' @param ofile chr, the name of the file to save with thr response content
#' @return 0 for success non-zero otherwise
fetch_dataset_description = function(dataset_id = "cmems_mod_glo_phy_myint_0.083deg_P1D-m",
                                     app = get_copernicus_app(),
                                     ofile = copernicus_path("catalogs",
                                                             sprintf("%s.json", dataset_id[1]))){
  cmd = sprintf("describe --disable-progress-bar --log-level ERROR --dataset-id %s > %s",
                dataset_id[1], ofile)
  system2(app, cmd)
}


#' Read the description for a dataset
#' 
#' @export
#' @param dataset_id chr, the dataset description to read
#' @param tabulate logical, if TRUE trasnform from list to nested table
#' @param flatten logical, if TRUE then flatten nested table (ignored if `tabulate = FALSE`)
#' @param service_name chr, if tabulating then the name of the service to tabulate. 
#'   The default is used by the CLI.
#' @param path chr the copernicus data path
#' @param fetch logical, if TRUE and the data was not previously downloaded, then
#'   try to fetch the data
#' @param x NULL or list, if not NULL then a list for a single dataset.  In this 
#'   case no attempt is made to read the file.
#' @return list, nested table or flat table
read_dataset_description = function(dataset_id = "cmems_mod_glo_phy_myint_0.083deg_P1D-m",
                                    tabulate = TRUE,
                                    flatten = TRUE,
                                    service_name = "arco-geo-series",
                                    path = copernicus_path("catalogs"),
                                    fetch = TRUE,
                                    x = NULL){
  
  if (is.null(x)){
    filename = file.path(path, sprintf("%s.json", dataset_id[1]))
    if(!file.exists(filename) && fetch) {
      ok = fetch_dataset_description(dataset_id[1])
      if (ok != 0) stop("unable to fetch the dataset description before reading")
    }
    x = jsonlite::read_json(filename)
  }
  
  if (tabulate){
    # x.products[0].datasets[0].versions[0].parts[0].services
    x = x[['products']][[1]][["datasets"]][[1]][["versions"]][[1]][["parts"]][[1]][['services']]
    names(x) <- sapply(x, function(subx) subx[['service_name']])
    x = x[[service_name[1]]][['variables']]
    x = if (flatten){
        # flatten
        flatten_variables(x, dataset_id = dataset_id)
      }  else { 
        # nested
        dplyr::mutate(x, dataset_id = dataset_id, .before = 1)
      }
  } # tabulate
  
  x
}

#' Flatten a dataset `variables` element
#' 
#' @export
#' @param x a `variables` node
#' @param dataset_id chr, the dataset_id to attach to the output
#' @return table or possibly filled with NAs if x is NULL
flatten_variables = function(x, dataset_id = "unknown"){
  if(is.null(x)) {
    now = Sys.time() + NA
    r = dplyr::tibble(
      dataset_id = dataset_id[1],
      short_name = NA_character_,
      standard_name = NA_character_,
      units = NA_character_,
      start_time = now,
      end_time = now,
      time_step = NA_real_,
      min_depth = NA_real_,
      max_depth = NA_real_
   ) 
   return(r)
  }
  short_name = sapply(x, "[[", "short_name")
  standard_name = sapply(x, "[[", "standard_name")
  units = sapply(x, "[[", "units")
  origin = as.POSIXct("1970-01-01 00:00:00Z", tz = "UTC")
  time = lapply(x, function(subx){
    y = subx[['coordinates']]
    names(y) <- sapply(y, `[[`, "coordinate_id")
    y = y[['time']]
    if ("minimum_value" %in% names(y)){
      r = c(y[["minimum_value"]], y[['maximum_value']], y[['step']]) |>
        as.numeric()
    } else {
      values = sapply(y$values, `[[`, 1) |> as.numeric() 
      r = range(values)
      step = (r[2] - r[1])/length(values)
      r = c(r, step)
    }
    r
  })
  time = if (length(time) == 1){
    matrix(time[[1]], ncol = 3) 
  } else {
    do.call(rbind, time)
  }
  step = time[,3, drop = TRUE]/1000
  time = as.POSIXct(time[,1:2, drop = FALSE]/1000, origin = origin, tz = "UTC")
  
  depth = lapply(x, function(subx){
    y = subx[['coordinates']]
    names(y) <- sapply(y, `[[`, "coordinate_id")
    y = y[['depth']]
    depth = if (is.null(y)){
      c(NA_real_, NA_real_)
    } else {
      range(y[['values']])
    }
  })
  depth = if (length(depth) == 1){
      matrix(depth[[1]], ncol = 2) 
    } else {
      do.call(rbind, depth)
    }
  
  
  dplyr::tibble(dataset_id = dataset_id[1],
                short_name = sapply(x, "[[", "short_name"),
                standard_name = sapply(x, "[[", "standard_name"),
                units = sapply(x, "[[", "units"),
                start_time = time[,1],
                end_time = time[,2],
                time_step = step,
                min_depth = depth[,1],
                max_depth = depth[,2])
}



#' Read a dataset service description as a table
#' 
#' @param x a dataset node
#' @param flatten logical if TRUE then flatten otherwise return nested table
#' @return table possibly nested or flattened
read_dataset_service = function(x, flatten = TRUE){
  x = x[['variables']]
  if (flatten){
    short_name = sapply(x, "[[", "short_name")
    standard_name = sapply(x, "[[", "standard_name")
    units = sapply(x, "[[", "units")
    origin = as.POSIXct("1970-01-01 00:00:00Z", tz = "UTC")
    time = lapply(x, function(subx){
      y = subx[['coordinates']]
      names(y) <- sapply(y, `[[`, "coordinate_id")
      y = y[['time']]
      c(y[["minimum_value"]], y[['maximum_value']], y[['step']]) |>
        as.numeric()
    })
    time = do.call(rbind, time)
    step = time[,3]/1000
    time = as.POSIXct(time[,1:2]/1000, origin = origin, tz = "UTC")
    
    x = dplyr::tibble(short_name = sapply(x, "[[", "short_name"),
                  standard_name = sapply(x, "[[", "standard_name"),
                  units = sapply(x, "[[", "units"),
                  start_time = time[,1],
                  end_time = time[,2],
                  time_step = step / 3600)
  } 
  x
}

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


#' Guess at the period of dataset given its id
#' 
#' @export
#' @param x one or more dataset_id values
#' @return chr vector of "day", "month", NA (unknown) etc
dataset_period = function(x = c("cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
                                "cmems_mod_glo_phy_anfc_0.083deg_P1M-m")){
  r = rep(NA_character_, length(x))
  r[grepl("P1D", x, fixed = TRUE)] <- "day"
  r[grepl("P1M", x, fixed = TRUE)] <- "month"
  r
}


#' Read the json dataset catalog
#' 
#' @export
#' @param filename chr the path to the file
#' @param tabulate logical, if TRUE transform to a table
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

#' Fetch the description for a product
#' 
#' @export
#' @param product_id chr, the product to describe
#' @param app chr, the `copernicusmarine` app
#' @param ofile chr, the name of the file to save with the response content
#' @return 0 for success non-zero otherwise
fetch_product_description = function(product_id = "GLOBAL_ANALYSISFORECAST_PHY_001_024",
                                     app = get_copernicus_app(),
                                     ofile = copernicus_path("catalogs",
                                                             sprintf("%s.json", product_id[1]))){
  cmd = sprintf("describe --disable-progress-bar --log-level ERROR --product-id %s > %s",
                product_id[1], ofile)
  system2(app, cmd)
}

#' Read the description for a product
#' 
#' @export
#' @param product_id chr, the product description to read
#' @param tabulate logical, if TRUE trasnform from list to nested table
#' @param flatten logical, if TRUE then flatten nested table (ignored if `tabulate = FALSE`)
#' @param service_name chr, if tabulating then the name of the service to tabulate. 
#'   The default is used by the CLI.
#' @param path chr the copernicus data path
#' @param fetch logical, if TRUE and the data was not previously downloaded, then
#'   try to fetch the data
#' @param x list of NULL, if NULL then we read the losting form file, if a 
#'   list we assume this is the product listing.
#' @return list, nested table or flat table
read_product_description = function(product_id = "GLOBAL_ANALYSISFORECAST_PHY_001_024",
                                    tabulate = TRUE,
                                    flatten = TRUE,
                                    service_name = "arco-geo-series",
                                    path = copernicus_path("catalogs"),
                                    fetch = TRUE,
                                    x = NULL){
  
  if (is.null(x)){
    filename = file.path(path, sprintf("%s.json", product_id[1]))
    if(!file.exists(filename) && fetch) {
      ok = fetch_product_description(product_id[1])
      if (ok != 0) stop("unable to fetch the product description before reading")
    }
    x = jsonlite::read_json(filename)
  }
  if (tabulate){
    x = x[['products']][[1]][["datasets"]]
    names(x) <- sapply(x, "[[", "dataset_id")
    x = lapply(names(x),
                function(nm){
                  #cat("dataset_id", nm, "\n")
                  y = x[[nm]][['versions']][[1]][["parts"]][[1]][['services']]
                  names(y) <- sapply(y, "[[", "service_name")
                  r = flatten_variables(y[[service_name]][["variables"]],
                                        dataset_id = nm)
                  r
                }) |>
      dplyr::bind_rows()
  }
  x
}

#' Flatten a particular product suite into one large table
#' 
#' @export
#' @param x nested catalog table
#' @return a flattened tables
flatten_product = function(x = read_product_catalog() |>
                            dplyr::filter(.data$product_id == "GLOBAL_ANALYSISFORECAST_PHY_001_024",
                                          grepl("P1D", .data$dataset_id, fixed = TRUE))){
 tidyr::unnest(x, cols = dplyr::everything())
}


#' Unpack a product element
#' 
#' @export
#' @param x json product list
#' @return a nested product table
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

#' Tabulate a product catalog
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
#' @param product_id chr, the prodict id to laod (or "all_products" if you have that)
#' @param path chr the path to the file
#' @param tabulate logical, if TRUE transform to a nested table
#' @param flatten logical, if TRUE and `tabulate` is TRUE then transofrm to a 
#'   flat table 
#' @return a named list of json element
read_product_catalog = function(product_id = "all_products",
                                path = copernicus_path("catalogs"),
                                tabulate = TRUE,
                                flatten = TRUE){
  filename = file.path(path[1], sprintf("%s.json", product_id[1]))
  x = jsonlite::read_json(filename)[['products']]
  names(x) <- sapply(x,
                     function(n){
                       n$product_id
                     })
  if (tabulate) {
    x = tabulate_product_catalog(x)
    if (flatten) x = tidyr::unnest(x, dplyr::all_of("vars"))
  }
  return(x)
}


#' Fetch the product catalog
#' 
#' @export
#' @param product_id chr, the product to describe or "all_products" to fetch all
#' @param app chr, the `copernicusmarine` app
#' @param ofile chr, the name of the file to save with the response content
#' @return 0 for success non-zero otherwise
fetch_product_catalog = function(product_id = "GLOBAL_ANALYSISFORECAST_PHY_001_024",
                                 app = get_copernicus_app(),
                                 ofile = copernicus_path("catalogs",
                                                         sprintf("%s.json", product_id[1]))){
  cmd = if (grepl("all", tolower(product_id[1]), fixed = TRUE)){
    sprintf("describe --disable-progress-bar --log-level ERROR > %s", ofile)
    } else {
      sprintf("describe --disable-progress-bar --log-level ERROR --product-id %s > %s",
               product_id[1], ofile)
    }
  system2(app, cmd)
}



#' Browse a product by id
#' 
#' @param product chr, the product id
#' @return hmmm, whatever [httr](BROWSE) returns
browse_product = function(product = "GLOBAL_ANALYSISFORECAST_BGC_001_028"){
  if (!requireNamespace("httr")){
    stop("please install the httr first")
  }
  tmp = "https://data.marine.copernicus.eu/PRODUCT_ID/description"
  tmp = gsub("PRODUCT_ID", product[1], tmp, fixed = TRUE)
  httr::BROWSE(tmp)
}