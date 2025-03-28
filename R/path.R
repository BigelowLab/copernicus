
#' Retrieve copernicus credentials.  One only needs credentials to download
#' data from the CMEMS servers.  Credentials are not required to access the locally
#' stored copernicus data (but file permissions are).
#' @rdname copernicus-deprecated
#' @export
#' @param filename the name file that stores the credential in a one-line text file
#'    as \code{username:password}
#' @param parse logical, if TRUE split the credentials and return as a named
#'   character vector
#' @return character \code{username:password}, a named vector or or NULL if the file is not found.
get_credentials <- function(filename = "~/.copernicuscredentials",
                            parse = TRUE){
  .Deprecated("",
              package = "copernicus",
              msg = "please use `copernicusmarine login` application instead")
  if (!file.exists(filename[1])){
    warning("credentials file not found:", filename[1])
    creds = NULL
  } else {
    creds = readLines(filename[1])
    if (parse[1]) {
      ss <- strsplit(creds, ":", fixed = TRUE)[[1]]
      creds = c(username = ss[[1]], password = ss[[2]])
    }
  }
  invisible(creds)
}


#' Write copernicus credentials to a file
#'
#' @rdname copernicus-deprecated
#' @export
#' @param x char, credentials as \code{"username:password"}
#' @param filename the name the file to store the credentials as a single line of text
#' @return NULL invisibly
set_credentials <- function(x = "username:password",
                          filename = "~/.copernicuscredentials"){
  .Deprecated("",
              package = "copernicus",
              msg = "please use `copernicusmarine login` application instead")
  cat(x[1], sep = "\n", file = filename)
  invisible(NULL)
}


#' Set the copernicus data path
#'
#' @export
#' @param path the path that defines the location of copernicus data
#' @param filename the name the file to store the path as a single line of text
#' @return NULL invisibly
set_root_path <- function(path = "/mnt/s1/projects/ecocast/coredata/copernicus",
                          filename = "~/.copernicusdata"){
  cat(path, sep = "\n", file = filename)
  invisible(NULL)
}

#' Get the copernicus data path from a user specified file
#'
#' @export
#' @param filename the name the file to store the path as a single line of text
#' @return character data path
root_path <- function(filename = "~/.copernicusdata"){
  readLines(filename)
}



#' Retrieve the copernicus path
#'
#' @export
#' @param ... further arguments for \code{file.path()}
#' @param root the root path
#' @return character path description
copernicus_path <- function(...,
  root = root_path()) {

  file.path(root, ...)
}

#' Given a path - make it if it doesn't exist
#'
#' @export
#' @param path character, the path to check and/or create
#' @param recursive logical, create paths recursively?
#' @param ... other arguments for \code{dir.create}
#' @return the path
make_path <- function(path, recursive = TRUE, ...){
  ok <- dir.exists(path[1])
  if (!ok){
    ok <- dir.create(path, recursive = recursive, ...)
  }
  path
}


#' Write `copernicusmarine` app path to a file
#'
#' @export
#' @param x char, the path to the `copernicusmarine` app
#' @param filename the name the file to store the path as a single line of text
#' @return NULL invisibly
set_copernicus_app <- function(x = "copernicusmarine",
                            filename = "~/.copernicusapp"){
  cat(x[1], sep = "\n", file = filename)
  invisible(NULL)
}


#' Retrieve `copernicusmarine` app  
#'
#' @export
#' @param filename the name the file
#' @return chr the known app (with path)
get_copernicus_app <- function(x = "copernicusmarine",
                               filename = "~/.copernicusapp"){
  if (!file.exists(filename[1])){
    warning("credentials file not found:", filename[1])
    app = "copernicusmarine"
  } else {
    app = readLines(filename[1])
  }
  app
}

