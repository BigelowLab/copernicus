suppressPackageStartupMessages({
  library(copernicus)
  library(stars)
  library(dplyr)
  library(charlier)
  library(argparser)
  library(cofbb)
  library(yaml)
})

DEST = "/mnt/s1/projects/ecocast/coredata/copernicus/examples"
bb = c(xmin = -70, ymin = 43, xmax = -69, ymax = 45)
product = "global-analysis-forecast-phy-001-024"


dataset_id = "cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m"
out_file = file.path(DEST, sprintf("%s__%s.nc", product, dataset_id))
download_copernicus_cli_subset(
  dataset_id = dataset_id,
  product = product,
  vars = product_lut(product[1]) |>
    dplyr::filter(datasetid == dataset_id) |>
    dplyr::pull(.data$variables) |>
    unlist(),
  bb = bb,
  depth = c(0, 10),
  time = c("2022-01-01", "2022-01-10"),
  ofile = out_file)




