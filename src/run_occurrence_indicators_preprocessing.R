#' R code to automatically create and move full_timeseries.csv.
#' This file is used at the alien species portal indicators page and has been 
#' created as part of the Trias - project. 
#' 
#' The final destination of the file is either the local alien-species-portal
#' folder or the UAT s3 bucket (WIP)

# Load script specific libraries
library(knitr)
library(dplyr)
library(magrittr)

# Check latest status on Trias indicators repo ####
## Update intersect_EEA_ref_grid_protected_areas.tsv ####
download.file(url = "https://raw.githubusercontent.com/trias-project/indicators/main/data/interim/intersect_EEA_ref_grid_protected_areas.tsv",
              destfile = "data/interim/intersect_EEA_ref_grid_protected_areas.tsv")

# create temporary R file
tempR <- tempfile(fileext = ".R")
knitr::purl("src/05_occurrence_indicators_preprocessing.Rmd", output=tempR)
source(tempR)
unlink(tempR)

