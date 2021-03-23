# Fetch 10 days of forecasts of Copernicus global-analysis-forecast-phy-001-024 data
# for the nwa region (today: (today + 9))
#
# fetch_copernicus
#   download file, open file, read as stars, close file, delete file
# save by slice var <prod>/nwa/yyyy/mmdd/date_var_depth.tif
# append database and write

library(copernicus)
library(stars)
library(dplyr)
library(logger)

fetch_one <- function(date){
  log_info("fetching date: %s", format(date, "%Y-%m-%d"))
  xx <- fetch_copernicus(date = date, banded = FALSE)
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
  for (i in seq_along(xx)) stars::write_stars(xx[[i]], files[i], driver = "GTiff")
  return(files)
}

dates <- Sys.Date() + c(0,seq_len(9))
logger::log_appender(logger::appender_tee(copernicus::copernicus_path("log")))
log_formatter(formatter_sprintf)

dataset <- file.path("global-analysis-forecast-phy-001-024", "nwa")
OPATH <- copernicus::copernicus_path("global-analysis-forecast-phy-001-024/nwa")

log_info("fetch_one: %s", dataset)
ff <- lapply(seq_along(dates), function(i) fetch_one(dates[i]))

log_info("updating database")
DB <- copernicus::read_database(OPATH)
db <- unlist(ff) %>%
  copernicus::decompose_filename() %>%
  copernicus::append_database(DB) %>%
  dplyr::arrange(date) %>%
  copernicus::write_database(OPATH)
log_success("done")
