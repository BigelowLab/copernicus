% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/script.R
\name{download_copernicus_script}
\alias{download_copernicus_script}
\title{Fetch (download) copernicus data}
\usage{
download_copernicus_script(x = populate_script())
}
\arguments{
\item{x}{charcater, a two element script vector comprised of
\itemize{
\item{app the name of the application to call, either python or python3}
\item{param the parameter (argument) vector fully populated}
}}
}
\value{
integer with 0 for success
}
\description{
Fetch (download) copernicus data
}
