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