% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/misc.R
\name{guess_period}
\alias{guess_period}
\title{Guess the time interval}
\usage{
guess_period(x, dimname = "time")
}
\arguments{
\item{x}{ncdf4 object or stars object}

\item{dimname}{char the time-dependent dimension name}
}
\value{
character string such as "day", "mon", "year" or "secs"
}
\description{
Guess the time interval
}
