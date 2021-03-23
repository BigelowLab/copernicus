# Fetch one day of Copernicus global-analysis-forecast-phy-001-024 data
# for the nwa region
#
# fetch_copernicus
#   download file, open file, read as stars, close file, delete file
# save by slice var <prod>/nwa/yyyy/mmdd/date_var_depth.tif
# append database and write

library(copernicus)
library(stars)
library(dplyr)


dates <- seq(from = as.Date("2019-01-31"), to = Sys.Date(), by = "day")
#dates <- seq(from = as.Date("2019-01-01"), to = as.Date("2019-01-30"), by = "day")
OPATH <- copernicus::copernicus_path("global-analysis-forecast-phy-001-024/nwa")
DB <- copernicus::read_database(OPATH)
ix <- dates %in% unique(DB$date)
dates <- dates[!ix]

for (i in seq_along(dates)){
  cat(format(dates[i], "%Y-%m-%d"), "\n")
  cmd <- sprintf("%s %s %s",
                 "Rscript",
                 "/mnt/ecocast/corecode/R/copernicus/inst/scripts/fetch_day.R",
                 format(dates[i], "%Y-%m-%d"))
  #ok <- system2("Rscript", cmd)
  ok <- system(cmd)
}

