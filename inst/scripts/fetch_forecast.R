# usage: fetch_forecast.R [--] [--help] [--date DATE] [--config CONFIG]
# 
# Fetch a copernicus forecast
# 
# flags:
#   -h, --help    show this help message and exit
# 
# optional arguments:
#   -d, --date    the date of the forecast [default: 2025-03-10]
#   -c, --config  configuration file [default:
#         /usr/lib64/R/library/copernicus/config/nwa_daily_fetch.yaml]
# 

# Fetch 10 days of forecasts of Copernicus global-analysis-forecast-phy-001-024 data
# for the nwa region (today: (today + 9))
#
# fetch_copernicus
#   download file, open file, read as stars, close file, delete file
# save by slice var <prod>/nwa/yyyy/mmdd/date_var_depth.tif
# append database and write

suppressPackageStartupMessages({
  library(copernicus)
  library(stars)
  library(dplyr)
  library(charlier)
  library(argparser)
  library(cofbb)
  library(yaml)
})

# Fetch one suite of forecasts (multiple vars, multiple depths, multiple times for 
# one dataset)
# @param date the date to fetch
# @param group the name of the cofuguration grop ("currents", "surface", "bottom", etc)
# @param cfg the configuration list
# @param out_path output path
# @param ahead number of days ahead to retrieve
fetch_one <- function(date, group,
                      cfg = NULL, 
                      out_path = NULL,
                      ahead = 9){
  
  dataset_id = cfg$dataset[[group]]$dataset_id[1]
  charlier::info("fetching %s on %s", dataset_id, format(date, "%Y-%m-%d"))
  
  xx <- copernicus::fetch_copernicus(dataset_id = dataset_id,
                                     vars = cfg$dataset[[group]][["vars"]],
                                     time = c(date, date + ahead),
                                     bb = cfg$bb,
                                     depth = cfg$dataset[[group]][["depth"]],
                                     log_level = cfg$log_level,
                                     verbose = TRUE)
  ff = generate_filename(xx, id = dataset_id)
  
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



main = function(date = Sys.Date(), cfg = NULL){
  
  if (!inherits(date, "Date")) date = as.Date(date)
  
  dates <- date + c(0,seq_len(9))
  
  P = copernicus::product_lut(cfg$product)

  out_path <- copernicus::copernicus_path(cfg$product, cfg$region)
  
  ff <- lapply(seq_along(dates), function(idate) {
      sapply(names(cfg$dataset), 
        function(what){
          fetch_one(dates[idate], what, cfg$dataset[[what]]$dataset_id, cfg = cfg, out_path = out_path)
        }) |>
       unlist()
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

Args = argparser::arg_parser("Fetch a copernicus forecast",
                             name = "fetch_forecast.R", 
                             hide.opts = TRUE) |>
  add_argument("--date",
               help = "the date of the forecast",
               default = format(Sys.Date() - 1, "%Y-%m-%d"),
               type = "charcacter") |>
  add_argument("--config",
               help = 'configuration file',
               default = system.file("config/nwa_daily_fetch_surface.yaml", package = "copernicus")) |>
  parse_args()


cfg = yaml::read_yaml(Args$config)
cfg$bb = cofbb::get_bb(cfg$region)
charlier::start_logger(copernicus::copernicus_path("log"))
if (!interactive()){
  ok = main(as.Date(Args$date), cfg )
  charlier::info("fetch_forecast: done")
  quit(save = "no", status = ok)
} else {
  date = as.Date(Args$date)
}



