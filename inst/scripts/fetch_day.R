# Fetch one day of Copernicus global-analysis-forecast-phy-001-024 data
# for the nwa region
#
# usage: fetch_day.R [--] [--help] [--date DATE] [--config CONFIG]
# 
# Fetch copernicus data for one day
# 
# flags:
#   -h, --help    show this help message and exit
# 
# optional arguments:
#   -d, --date    the date of the forecast [default: 2025-03-11]
#   -c, --config  configuration file [default:
#                    /mnt/s1/projects/ecocast/corecode/R/copernicus/inst/config/nwa_daily_fetch_surface.yaml]


suppressPackageStartupMessages({
  library(copernicus)
  library(stars)
  library(dplyr)
  library(charlier)
  library(argparser)
  library(cofbb)
  library(yaml)
})



fetch_one <- function(date, dataset_id, cfg = NULL, out_path = NULL){
  dataset_id = dataset_id[1]
  charlier::info("fetching %s on %s", dataset_id, format(date, "%Y-%m-%d"))
  
  xx <- copernicus::fetch_copernicus(dataset_id = dataset_id,
                                     vars = cfg$dataset[[dataset_id]][["vars"]],
                                     time = c(date, date + 1),
                                     bb = cfg$bb,
                                     depth = cfg$dataset[[dataset_id]][["depth"]],
                                     log_level = cfg$log_level,
                                     verbose = TRUE)
  depth <- rep("sur", length(xx))
  ix <- grepl("bottom", names(xx), fixed = TRUE)
  depth[ix] <- "bot"
  path <- file.path(out_path,
                    format(date, "%Y"),
                    format(date, "%m%d"))
  stopifnot(make_path(path))
  
  lut = copernicus::product_lut(cfg$product) |>
    dplyr::filter(.data$datasetid == dataset_id[1]) |>
    dplyr::pull(dplyr::all_of("period"))
  
  files <- file.path(path,
                     sprintf("%s_%s_%s_%s_%s.tif",
                             format(date, "%Y-%m-%d"),
                             period,
                             names(xx),
                             depth,
                             treatment = "none"))
  for (i in seq_along(xx)) stars::write_stars(xx[i], files[i])
  return(files)
}



main = function(date = Sys.Date()-1, cfg = NULL){
  
  if (!inherits(date, "Date")) date = as.Date(date)
  
  P = copernicus::product_lut(cfg$product) |>
    dplyr::filter(fetch == "yes") |>
    dplyr::group_by(product_id)
  
  
  # productid/region/yyyy/mmdd/datasetid__time_depth_period_var_treatment.ext
  out_path <- copernicus::copernicus_path(cfg$product, 
                                          cfg$region, 
                                          format(date, "%Y"),
                                          format(date, "%m%d"))
  ss = P |>
        fetch_product_by_day(x = date, bb = cfg$bb)

  ff = lapply(names(ss),
    function(dataset){
      if (is.null(ss[[dataset]])) return(NULL)
      vars = names(ss[[dataset]])
      depth = filter(P, dataset_id == dataset) |>
        dplyr::filter(short_name %in% vars) |>
        dplyr::pull(dplyr::all_of("depth"))
      time = format(date, "%Y-%m-%dT000000")  
      per = dataset_period(dataset)
      treatment = "raw"
      # productid/region/yyyy/mmdd/datasetid__time_depth_period_var_treatment.ext
      f = file.path(out_path, 
                    sprintf("%s__%s_%s_%s_%s_%s.tif", dataset, time, depth, per, vars, treatment))
      ok = copernicus::make_path(dirname(f) |> unique())
      for (i in seq_along(names(ss[[dataset]]))) {
        stars::write_stars(ss[[dataset]][i], f[i])
      }
      f
    })
  
  
  charlier::info("fetch_forecast:updating database")
  DB <- copernicus::read_database(out_path)
  db <- unlist(ff) %>%
    copernicus::decompose_filename() %>%
    copernicus::append_database(DB) %>%
    dplyr::arrange(date) %>%
    copernicus::write_database(out_path)
  return(0)
}

Args = argparser::arg_parser("Fetch copernicus data for one day",
                             name = "fetch_day.R", 
                             hide.opts = TRUE) |>
  add_argument("--date",
               help = "the date of the forecast",
               default = format(Sys.Date(), "%Y-%m-%d"),
               type = "charcacter") |>
  add_argument("--config",
               help = 'configuration file',
               default = system.file("config/fetch_day.yaml", package = "copernicus")) |>
  parse_args()


cfg = yaml::read_yaml(Args$config)
cfg$bb = cofbb::get_bb(cfg$region)
charlier::start_logger(copernicus::copernicus_path("log"))
if (!interactive()){
  ok = main(as.Date(Args$date), cfg )
  charlier::info("fetch_day: done")
  quit(save = "no", status = ok)
} else {
  date = as.Date(Args$date)
}



