# Fetch one day of Copernicus global-analysis-forecast-phy-001-024 data
# for the nwa region
#
# fetch_copernicus
#   download file, open file, read as stars, close file, delete file
# save by slice var <prod>/nwa/yyyy/mmdd/date_var_depth.tif
# append database and write

suppressPackageStartupMessages({
  library(charlier)
  library(copernicus)
  library(stars)
  library(dplyr)
})

charlier::start_logger(copernicus::copernicus_path("log"))

date <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(date) || length(date) == 0) {
  date <- Sys.Date()
}
date <- as.Date(date)

charlier::info("fetch_day: %s", format(date, "%Y-%m-%d"))

OPATH <- copernicus::copernicus_path("global-analysis-forecast-phy-001-024/nwa")
DB <- copernicus::read_database(OPATH)


fetch_product = function(tbl, key, date = Sys.Date()){
  
  cat("product_id:", tbl$product_id[1], "\n")
  cat("variables:", paste(tbl$name, collapse = ", "), "\n")
  xx <- fetch_copernicus(date = date, 
                         product_id = tbl$product_id[1],
                         variables = tbl$name,
                         banded = FALSE)
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
  ff
}


db <- merge_lut() |>
  dplyr::group_by(product_id) |>
  dplyr::group_map(fetch_product, date = date, .keep = TRUE) |>
  unlist() |>
  copernicus::decompose_filename() |>
  dplyr::bind_rows(DB) |>
  dplyr::distinct() |>
  copernicus::write_database(OPATH)


# xx <- fetch_copernicus(date = date, banded = FALSE)
# depth <- rep("sur", length(xx))
# ix <- grepl("bottom", names(xx), fixed = TRUE)
# depth[ix] <- "bot"
# path <- file.path(OPATH,
#                   format(date, "%Y"),
#                   format(date, "%m%d"))
# stopifnot(make_path(path))
# files <- file.path(path,
#                   sprintf("%s_%s_%s.tif",
#                     format(date, "%Y-%m-%d"),
#                     names(xx),
#                     depth))
# for (i in seq_along(xx)) stars::write_stars(xx[[i]], files[i], driver = "GTiff")
# 
# DB <- copernicus::append_database(DB, copernicus::decompose_filename(files)) %>%
#   copernicus::write_database(OPATH)




