
#' @author Yingjie Zhang
#' 
#' @description
#' This R-script uploads the necessary files, which need to be processsed, to the UAT S3 bucket to test the 
#' development evironment of the [alien species portal]
#' 
#' @details 
#' This script uses `./src/connect_to_bucket.R` to generate a access token 
#' needed to access the bucket. 

# Libraries ####
library(aws.s3)
library(alienSpecies) # for all the create* functions
library(testthat)


processingFilePath <- "./data/output/UAT_processing"

# connect to bucket ####
source("./src/connect_to_bucket.R")

bucket <-  Sys.getenv("UAT_bucket")

###############################################################
## The following create* function will take input data, 
## process it and put them on s3 bucket 
## Connection to S3 bucket should be in place by this point
###############################################################

# input: folder grid containing gewestbel shape data
# output: grid.RData 
createShapeData(dataDir = file.path(processingFilePath, "grid"))

# input Vespa_velutina_shape" folder containing shape data
# output: Vespa_velutina_shape.RData
createShapeData(dataDir = file.path(processingFilePath,"Vespa_velutina_shape"))

# input: folder occurrenceCube containing be_1km and be_20 km shape data
# output: occurrenceCube.RData
createShapeData(dataDir = file.path(processingFilePath,"occurrenceCube"))

# output: provinces.RData
createShapeData(dataDir = file.path(processingFilePath,"provinces.geojson"))

# output: communes.RData
createShapeData(dataDir = file.path(processingFilePath,"communes.geojson"))

# create key data
# input:  "be_alientaxa_info.csv"
# output: "keys.csv"
createKeyData(dataDir = processingFilePath)

# create time series data
# input:  "df_timeseries.tsv" and "grid.RData" from bucket
# note: due to the size of "df_timeseries.tsv", it's not tracked, user needs to provide the parent folder to "df_timeseries.tsv".
# output: full_timeseries.RData

createTimeseries(
  dataDir = processingFilePath,
  # read grid.RData from bucket
  shapeData = loadShapeData("grid.RData")$utm1_bel_with_regions
)

# create occupancy cube 

# input: trendOccupancy folder containing T1* and ias_belgium_t0_2016/18/20 geojson data
# output: dfCube.RData
createOccupancyCube(file.path(processingFilePath, "trendOccupancy"))

# create tabular data
# input: data_input_checklist_indicators.tsv/eu_concern_species.tsv/be_alientaxa_cube.csv
# output: "eu_concern_species_processed.RData"/"data_input_checklist_indicators_processed.RData"/ "be_alientaxa_cube_processed.RData" 

createTabularData(dataDir =  processingFilePath, type = "indicators")
createTabularData(dataDir =  processingFilePath, type = "unionlist")
createTabularData(dataDir = processingFilePath, type = "occurrence")

###################################################
# test if all the data files needed are on bucket #
# and can be read into R                          #
###################################################

test_that("Load shape data", {
  
  allShapes <- c(
    # Grid data
    loadShapeData("grid.RData"),
    loadShapeData("occurrenceCube.RData"),
    # gemeentes & provinces
    "provinces" = list(loadShapeData("provinces.RData")),
    "communes" = list(loadShapeData("communes.RData"))
  )
  
  expect_gt(length(  allShapes), 1)
  
  ## be_10km and be_1km is currently not loaded due to missing region
  # expect_setequal(
  # c("gewestbel", "utm1_bel_with_regions", "utm10_bel_with_regions","be_10km", "be_1km","provinces","communes"  ) , names(allShapes)
  #   
  # )  
  
})



test_that("Load indicatorsData", {
  exotenData <- loadTabularData(type = "indicators")
  expect_s3_class(   exotenData, "data.table")
})


test_that("Load unionlistData", {
  unionlistData <- loadTabularData(type = "unionlist")
  
  expect_s3_class( unionlistData, "data.table")
  
})

test_that("Load occurrenceData", {
  occurrenceData <- loadTabularData(type = "occurrence")
  expect_s3_class( occurrenceData, "data.table")
  
})



test_that("Load full_timeseries", {
  readS3(file = "full_timeseries.RData")
  expect_true(exists("timeseries"))
  expect_s3_class(timeseries, "data.table")
})


test_that("Load cube data", {
  
  occupancy <- loadOccupancyData()
  expect_true(exists("dfCube"))
  expect_s3_class(occupancy, "data.table")
})


test_that("Load Vespa_velutina_shape", {
  
  Vespa_velutina_shape <- loadShapeData("Vespa_velutina_shape.RData")
  expect_type(Vespa_velutina_shape, "list")
  
})


