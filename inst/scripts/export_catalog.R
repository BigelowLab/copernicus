# usage: export_catalog [--] [--help] catalog_file export_file
# 
# Export Copernicus JSON catalog to CSV (well, RDS)
# 
# positional arguments:
#   catalog_file  the catalog filename
# 
# flags:
#   -h, --help    show this help message and exit

suppressPackageStartupMessages({
  library(copernicus)
  library(dplyr)
  library(readr)
  library(argparser)
})


ARGS = arg_parser("Export Copernicus JSON catalog to CSV (RDS)",
                  name = "export_catalog",
                  hide.opts = TRUE) |>
  add_argument("catalog_file", 
               help = "the catalog filename",
               type = "character") |>
  parse_args()

inpath = dirname(ARGS$catalog_file)
iname = gsub(".json", "", basename(ARGS$catalog_file), fixed = TRUE)
ofile = paste0(iname, ".rds")



x = copernicus::read_product_catalog(iname, path = inpath, import = TRUE) |>
  readr::write_rds(file = file.path(inpath, ofile))