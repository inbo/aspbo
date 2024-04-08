#' @author Sander Devisscher
#' 
#' @description
#' Script to download and map management data for Oxyura jamaicensis.
#' 
#' Datasources:
#' - https://www.gbif.org/dataset/7522721f-4d97-4984-8231-c9e061ef46df
#' 
#' Output:
#' - ./data/output/UAT_direct/Oxyura_jamaicensis.csv

# Libraries ####
library(alienSpecies)
library(tidyr)
library(magrittr)
library(dplyr)
library(sf)

# download data from gbif ####
# using alienSpecies::getGbifOccurrence()
datasetKey <- c("7522721f-4d97-4984-8231-c9e061ef46df")

getGbifOccurrence(datasetKey,
                  bucket = Sys.getenv("UAT_bucket"),
                  user = Sys.getenv("gbif_user"),
                  pwd = Sys.getenv("gbif_pwd"),
                  email = Sys.getenv("email"),
                  outFile = "Oxyura_jamaicensis.csv")

