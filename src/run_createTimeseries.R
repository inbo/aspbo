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