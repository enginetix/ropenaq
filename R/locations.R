#' Providing data about distinct measurement locations.
#'
#' @imports dplyr
#' @imports lubridate
#'
#' @param city 	Limit results by a certain city.
#' @param country Limit results by a certain country.
#' @param location Limit results by a certain location.
#' @param parameter Limit to only a certain parameter (valid values are "pm25", "pm10", "so2", "no2", "o3", "co" and "bc").
#' If no parameter is given, all parameters are retrieved.
#' @param has_geo Filter out items that have or do not have geographic information.Can only be TRUE for now.
#' @param value_from Show results above value threshold, useful in combination with \code{parameter}.
#' @param value_to Show results below value threshold, useful in combination with \code{parameter}.
#' @param date_from Show results after a certain date. (ex. "2015-12-20").
#' @param date_to Show results before a certain date. (ex. "2015-12-20")
#'
#' @return A data.table with for each location: its name, the city and the country it is in, the number of measures for this location,
#'  the name of the source, and the dates and times at which it was first and last updated, respectively.
#' @export
#'
#' @examples
#' locations(country="IN")
locations <- function(city=NULL,
                      country=NULL,
                      location=NULL,
                      parameter=NULL,
                      has_geo=NULL,
                      value_from=NULL,
                      value_to=NULL,
                      date_from=NULL,
                      date_to=NULL){

  query <- "https://api.openaq.org/v1/locations?"

  # country
  if(!is.null(country)){
    if(!(country%in%countries()$code)){stop("This country is not available within the platform.")}
    query <- paste0(query, "&country=", country)
  }

  # city
  if(!is.null(city)){
    query <- paste0(query, "&city=", city)
  }

  # location
  if(!is.null(location)){
    query <- paste0(query, "&location=", location)
  }
  # parameter
  if(!is.null(parameter)){
    if(!(parameter%in%c("pm25", "pm10", "so2", "no2", "o3", "co", "bc"))){
      stop("You asked for an invalid parameter: see list of valid parameters in the Arguments section of the function help")
    }
    query <- paste0(query, "&parameter=", parameter)
  }
  # has_geo
  if(!is.null(has_geo)){
    if(has_geo==TRUE){
      query <- paste0(query, "&has_geo=1")
    }

  }

  # check dates
  if(!is.null(date_from)&!is.null(date_to)){
    if(ymd(date_from)>ymd(date_to)){
      stop("The start date must be smaller than the end date.")
    }

  }

  # date_from
  if(!is.null(date_from)){
    query <- paste0(query, "&date_from=", date_from)
  }
  # date_to
  if(!is.null(date_to)){
    query <- paste0(query, "&date_to=", date_to)
  }

  # check values
  if(!is.null(value_from)&!is.null(value_to)){
    if(value_to<value_from){
      stop("The max value must be bigger than the min value.")
    }

  }
  # value_from
  if(!is.null(value_from)){
    if(value_from<0){stop("No negative values please!")}
    query <- paste0(query, "&value_from=", value_from)
  }

  # value_to
  if(!is.null(value_to)){
    if(value_to<0){stop("No negative values please!")}
    query <- paste0(query, "&value_to=", date_to)
  }

  if(identical(as.character("https://api.openaq.org/v1/locations?"), as.character(query))){
    query <- "https://api.openaq.org/v1/locations"
  }
  # get results

  page <- httr::GET(query)

  contentPage <- httr::content(page)
  if(length(contentPage[[2]])==0){stop("No results for this query")}
  else{
    location <- unlist(lapply(contentPage[[2]], function (x) x['location']))
    city <- unlist(lapply(contentPage[[2]], function (x) x['city']))
    country <- unlist(lapply(contentPage[[2]], function (x) x['country']))
    count <- unlist(lapply(contentPage[[2]], function (x) x['count']))
    sourceName <- unlist(lapply(contentPage[[2]], function (x) x['sourceName']))
    firstUpdated <- unlist(lapply(contentPage[[2]], function (x) x['firstUpdated']))
    lastUpdated <- unlist(lapply(contentPage[[2]], function (x) x['lastUpdated']))
    parameters <- unlist(lapply(contentPage[[2]], function (x) toString(unlist(x["parameters"]))))

    locationsTable <- dplyr::tbl_df(
      data.frame(location=location,
                 city=city,
                 country=country,
                 count=count,
                 sourceName=sourceName,
                 firstUpdated=firstUpdated,
                 lastUpdated=lastUpdated,
                 parameters=parameters))%>%
      dplyr::mutate(firstUpdated=lubridate::ymd_hms(firstUpdated),
                    lastUpdated=lubridate::ymd_hms(lastUpdated))

    geoCoordLat <- function(x){
      if(is.null(x$coordinates$latitude)){
        return(NA)
      }
      else(return(x$coordinates$latitude))
    }

    geoCoordLong <- function(x){
      if(is.null(x$coordinates$longitude)){
        return(NA)
      }
      else(return(x$coordinates$longitude))
    }

    if(!is.null(unlist(lapply(contentPage[[2]], function (x) x$coordinates$latitude)))){
      latitude <- unlist(lapply(contentPage[[2]], geoCoordLat))
      longitude <- unlist(lapply(contentPage[[2]], geoCoordLong))
      locationsTable <- dplyr::mutate(locationsTable, latitude=latitude, longitude=longitude)
    }


    return(locationsTable)
  }
}