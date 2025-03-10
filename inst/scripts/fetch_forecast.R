# usage: fetch_forecast.R [--] [--help] [--date DATE] [--dataset DATASET]
# [--region REGION]
# 
# Fetch a copernicus forecast
# 
# flags:
#   -h, --help    show this help message and exit
# 
# optional arguments:
#   -d, --date    the date of the forecast [default: 2025-03-10]
#   --dataset     dataset id [default: global-analysis-forecast-phy-001-024]
#   -r, --region  region identifier, used for path and bounding box definitions [default: nwa]


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
})

fetch_one <- function(date){
  charlier::info("fetching date: %s", format(date, "%Y-%m-%d"))
  xx <- copernicus::fetch_copernicus(time = c(date, date + 1))
  depth <- rep("sur", length(xx))
  ix <- grepl("bottom", names(xx), fixed = TRUE)
  depth[ix] <- "bot"
  path <- file.path(OPATH,
                    format(date, "%Y"),
                    format(date, "%m%d"))
  stopifnot(make_path(path))
  files <- file.path(path,
                     sprintf("%s_%s_%s.tif",
                             format(date, "%Y-%m-%d"),
                             names(xx),
                             depth))
  for (i in seq_along(xx)) stars::write_stars(xx[[i]], files[i])
  return(files)
}


main = function(date = Sys.Date(),
                dataset_id = "global-analysis-forecast-phy-001-024",
                region = "nwa",
                bb = cofbb::get_bb("nwa")){
  dates <- date + c(0,seq_len(9))
  charlier::start_logger(copernicus::copernicus_path("log"))
  
  dataset <- file.path("global-analysis-forecast-phy-001-024", "nwa")
  OPATH <- copernicus::copernicus_path(dataset)
  
  charlier::info("fetch_forecast: %s", dataset)
  ff <- lapply(seq_along(dates), function(i) fetch_one(dates[i]))
  
  charlier::info("fetch_forecast:updating database")
  DB <- copernicus::read_database(OPATH)
  db <- unlist(ff) %>%
    copernicus::decompose_filename() %>%
    copernicus::append_database(DB) %>%
    dplyr::arrange(date) %>%
    copernicus::write_database(OPATH)
  return(0)
}

Args = argparser::arg_parser("Fetch a copernicus forecast",
                             name = "fetch_forecast.R", 
                             hide.opts = TRUE) |>
  add_argument("--date",
               help = "the date of the forecast",
               default = format(Sys.Date(), "%Y-%m-%d"),
               type = "charcacter") |>
  add_argument("--dataset",
               help = 'dataset id',
               default = "global-analysis-forecast-phy-001-024") |>
  add_argument("--region",
               help = "region identifier, used for path and bounding box definitions",
               default = "nwa") |>
  parse_args()


if (!interactive()){
  ok = main(date = as.Date(Args$date),
            dataset_id = Args$dataset,
            region = Args$region,
            bb = cofbb::get_bb(Args$region))
  charlier::info("fetch_forecast: done")
  quit(save = "no", status = ok)
} else {
  date = as.Date(Args$date)
  dataset_id = Args$dataset
  region = Args$region
  bb = cofbb::get_bb(Args$region)
}



