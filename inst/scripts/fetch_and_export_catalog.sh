#! bin/sh

# Used to fetch and convert the complete CMEMS Marine Data Store catalog
DATAPATH=/mnt/ecocast/coredata/copernicus/catalogs
SCRIPTPATH=/mnt/ecocast/corecode/R/copernicus/inst/scripts/
copernicusmarine describe > ${DATAPATH}/all_products_copernicus_marine_service.json

Rscript ${SCRIPTPATH}/export_catalog.R ${DATAPATH}/all_products_copernicus_marine_service.json