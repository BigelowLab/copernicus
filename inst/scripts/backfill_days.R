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

#' @param date a single Date
#' @param cfg the configuration
#' @param data_path the data directory
fetch_this_day = function(date, cfg, data_path, P){
  charlier::info("backfill_days: fetching %s", format(date, "%Y-%m-%d"))
  #daynum = format(date, "%d")
  #if (daynum == "01") charlier::info("backfill_days:fetching %s", format(date, "%Y-%b"))
  
  out_path <- copernicus::copernicus_path(cfg$product, 
                                          cfg$region, 
                                          format(date, "%Y"),
                                          format(date, "%m%d"))
  ss = try( P |>
    fetch_product_by_day(x = date, bb = cfg$bb))
  if (inherits(ss, "try-error")){
    MISSED_COUNT <<- MISSED_COUNT + 1
    charlier::warn("backfill_days: failed to fetch %s", format(date, "%Y-%m-%d"))
    return(NULL)
  }
  isnull = sapply(ss, is.null)
  ss = ss[!isnull]
  if (length(ss) == 0){
    MISSED_COUNT <<- MISSED_COUNT + 1
    charlier::warn("backfill_days: unable to fetch %s", format(date, "%Y-%m-%d"))
    return(NULL)
  }
  
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
  
  unlist(ff) %>%
    copernicus::decompose_filename() 
}

main = function(cfg = NULL){
  
  P = copernicus::product_lut(cfg$product) |>
    dplyr::filter(fetch == "yes") |>
    dplyr::group_by(product_id)
  
  data_path = copernicus::copernicus_path(cfg$product,  cfg$region)
  ok = make_path(data_path)
  start_date = as.Date(cfg$first_date)
  end_date = Sys.Date()
  all_dates = seq(from = start_date, to = end_date, by = "day")
  
  if (file.exists(copernicus::copernicus_path(cfg$product, 
                                              cfg$region, 
                                              "database"))){
    DB = read_database(data_path)
    missing_dates <- all_dates[!(all_dates %in% DB$date)]
  } else {
    missing_dates = all_dates
  }
  charlier::info("backfill_days: missing %i days", length(missing_dates))
  
  # here we do an explicit loop as we wish to optionally terminate the 
  # process early if we miss three or more dates - which likely implies...
  # a. the date(s) are not available
  # b. credentials are messed up somehow
  # c. catalog/dataset mash up?
  
  # an emplyt list of the needed length
  dbs = vector(mode = "list", length = length(missing_dates))
  # loop through - testing for missing each time, break if exceeded
  # 
  for (i in seq_along(missing_dates)){
    dbs[[i]] = fetch_this_day(missing_dates[i], cfg, data_path, P)
    if (MISSED_COUNT > MAX_MISSED_COUNT) break
  }
  
  dbs =  dplyr::bind_rows(dbs)
  
  if (nrow(dbs) > 0) DB = dbs |> append_database(data_path)
  
  return(0)
}

Args = argparser::arg_parser("Backfill copernicus data",
                             name = "backfill_days.R", 
                             hide.opts = TRUE) |>
  add_argument("--config",
               help = 'configuration file',
               default = system.file("config/fetch-day-GLOBAL_MULTIYEAR_PHY_001_030.yaml", 
                                     package = "copernicus", lib.loc = .libPaths()[1])) |>
  parse_args()


cfg = yaml::read_yaml(Args$config)
cfg$bb = cofbb::get_bb(cfg$region)
charlier::start_logger(copernicus_path(cfg$product, cfg$reg, "log"))
charlier::info("backfill_days for %s", cfg$product)

MAX_MISSED_COUNT = 3
MISSED_COUNT = 0

if (!interactive()){
  ok = main( cfg )
  charlier::info("backfill_days: done")
  quit(save = "no", status = ok)
} else {
  date = as.Date(Args$date)
}


