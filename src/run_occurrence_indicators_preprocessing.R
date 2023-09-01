#' R code to automatically run all chunks of fetch_data.Rmd

# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("knitr", "dplyr", "magrittr")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}
library(knitr)
library(dplyr)
library(magrittr)
# Check latest status on Trias indicators repo
download.file(url = "https://raw.githubusercontent.com/trias-project/indicators/main/src/05_occurrence_indicators_preprocessing.Rmd",
              destfile = "src/05_occurrence_indicators_preprocessing.Rmd",
              method = "curl")

download.file(url = "https://raw.githubusercontent.com/trias-project/indicators/main/data/interim/data_input_checklist_indicators.tsv",
              destfile = "data/interim/data_input_checklist_indicators.tsv")

download.file(url = "https://raw.githubusercontent.com/trias-project/indicators/main/data/interim/intersect_EEA_ref_grid_protected_areas.tsv",
              destfile = "data/interim/intersect_EEA_ref_grid_protected_areas.tsv")

# create temporary R file
tempR <- tempfile(fileext = ".R")
knitr::purl("src/05_occurrence_indicators_preprocessing.Rmd", output=tempR)
source(tempR)
unlink(tempR)

# update alienSpecies ####
inbotheme_version <- as.data.frame(installed.packages()) %>% 
  filter(Package == "INBOtheme")

if(inbotheme_version$Version != "0.5.8"){
  remove.packages("INBOtheme")
  devtools::install_github("inbo/INBOtheme@v0.5.8")
}

devtools::install_github("inbo/alien-species-portal@sprint_v0.0.4", 
                         subdir = "alienSpecies", force = TRUE)


alienSpecies::createTimeseries(dataDir = "./data/interim/",
                               shapeData = alienSpecies::readShapeData()$utm1_bel_with_regions,
                               packageDir = "../alien-species-portal/alienSpecies/inst/extdata/")
