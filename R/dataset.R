# https://help.marine.copernicus.eu/en/articles/6820094-how-is-defined-the-nomenclature-of-copernicus-marine-data

#' Parse one or more dataset_id values
#'
#' @export
#' @param x one or more dataset_id values
#' @param detect_period logical, if TRUE, add a column, `.period` with 'day', 'month' etc
#'   based upon a best guess from the `temporalres` segment (last segment of id)
#' @return table of parsed elements
parse_dataset_id = function(x = c("cmems_mod_glo_phy-cur_anfc_0.083deg_P1D-m", 
                                  "cmems_mod_glo_phy-so_anfc_0.083deg_P1D-m",
                                  "cmems_mod_glo_phy-thetao_anfc_0.083deg_P1D-m", 
                                  "cmems_mod_glo_phy-wcur_anfc_0.083deg_P1D-m", 
                                  "cmems_mod_glo_phy_anfc_0.083deg-sst-anomaly_P1D-m", 
                                  "cmems_mod_glo_phy_anfc_0.083deg_P1D-m"),
                            detect_period = TRUE){
  
 ss = strsplit(x, "_", fixed = TRUE)
 r = dplyr::tibble(
   origin = sapply(ss, `[[`, 1),
   group = sapply(ss, `[[`, 2),
   area = sapply(ss, `[[`, 3),
   thematic = sapply(ss, `[[`, 4),
   type = sapply(ss, `[[`, 5),
   compinfo = sapply(ss, `[[`, 6),
   temporalres = sapply(ss, `[[`, 7))
 if (detect_period){
   r = dplyr::mutate(r,
                     .period = dplyr::if_else(grepl("^P.*D", .data$temporalres),
                                              "day", 
                                              "month",
                                              missing = NA_character_))
 }
 r
}