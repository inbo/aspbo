#' R code to automatically create and move full_timeseries.csv.
#' This file is used at the alien species portal indicators page and has been 
#' created as part of the Trias - project. 
#' 
#' The final destination of the file is either the local alien-species-portal
#' folder or the UAT s3 bucket (WIP)

# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("knitr", "dplyr", "magrittr", "rgbif", "tidylog", 
              "progress", "here", "lubridate", "readr", "purrr",
              "stringr")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}

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

# update alienSpecies 
inbotheme_version <- as.data.frame(installed.packages()) %>% 
  filter(Package == "INBOtheme")

if(inbotheme_version$Version != "0.5.8"){
  remove.packages("INBOtheme")
  devtools::install_github("inbo/INBOtheme@v0.5.8")
}

devtools::install_github("inbo/alien-species-portal@sprint_v0.0.4", 
                         subdir = "alienSpecies", force = TRUE)

# Create full_timeseries.csv
alienSpecies::createTimeseries(dataDir = "./data/interim/",
                               shapeData = alienSpecies::readShapeData()$utm1_bel_with_regions,
                               packageDir = "./data/output/")

# Move full_timeseries.csv to the correct location
## Locally to app folder
file.copy(from = "./data/output/full_timeseries.csv",
          to = "../alien-species-portal/alienSpecies/inst/extdata/full_timeseries.csv",
          overwrite = TRUE)

## To UAT 
#### WIP ####