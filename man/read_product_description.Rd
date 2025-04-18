% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/catalog.R
\name{read_product_description}
\alias{read_product_description}
\title{Read the description for a product}
\usage{
read_product_description(
  product_id = "GLOBAL_ANALYSISFORECAST_PHY_001_024",
  tabulate = TRUE,
  flatten = TRUE,
  service_name = "arco-geo-series",
  path = copernicus_path("catalogs"),
  fetch = TRUE,
  x = NULL
)
}
\arguments{
\item{product_id}{chr, the product description to read}

\item{tabulate}{logical, if TRUE trasnform from list to nested table}

\item{flatten}{logical, if TRUE then flatten nested table (ignored if `tabulate = FALSE`)}

\item{service_name}{chr, if tabulating then the name of the service to tabulate. 
The default is used by the CLI.}

\item{path}{chr the copernicus data path}

\item{fetch}{logical, if TRUE and the data was not previously downloaded, then
try to fetch the data}
}
\value{
list, nested table or flat table
}
\description{
Read the description for a product
}
