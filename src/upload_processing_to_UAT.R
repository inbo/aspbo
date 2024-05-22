
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
#source("./src/connect_to_bucket.R")

# test S3_bucket ####
test_that("Check S3_BUCKET env variable", {
    
    expect_false(Sys.getenv("S3_BUCKET") == "", "env S3_BUCKET is not provided")
    
  })

bucket <- paste0("s3://",Sys.getenv("S3_BUCKET"))
print(bucket)

#Sys.setenv("AWS_DEFAULT_REGION" = "eu-west-1")

#connect_to_bucket(bucket) #=> run this before continuing locally

###############################################################
## The following create* function will take input data, 
## process it and put them on s3 bucket 
## Connection to S3 bucket should be in place by this point
###############################################################

# input: folder grid containing gewestbel shape data
# output: grid.RData 
print("grid")
createShapeData(dataDir = file.path(processingFilePath, "grid"), bucket = bucket)

# input Vespa_velutina_shape" folder containing shape data
# output: Vespa_velutina_shape.RData
print("Vespa velutina")
createShapeData(dataDir = file.path(processingFilePath,"Vespa_velutina_shape"), bucket = bucket)

# input: folder occurrenceCube containing be_1km and be_20 km shape data
# output: occurrenceCube.RData
print("occurrenceCube")
createShapeData(dataDir = file.path(processingFilePath,"occurrenceCube"), bucket = bucket)

# output: provinces.RData
print("provinces")
createShapeData(dataDir = file.path(processingFilePath,"provinces.geojson"), bucket = bucket)

# output: communes.RData
print("communes")
createShapeData(dataDir = file.path(processingFilePath,"communes.geojson"), bucket = bucket)

# input: data_input_checklist_indicators.tsv
# output: "data_input_checklist_indicators_processed.parquet" 
print("indicators")
createTabularData(dataDir =  processingFilePath, type = "indicators", bucket = bucket)

# create key data
# input:  "be_alientaxa_info.csv"
# output: "keys.csv"
print("key data")
createKeyData(dataDir = processingFilePath, bucket = bucket)

# create occupancy cube 
# input: trendOccupancy folder containing T1* and ias_belgium_t0_2016/18/20 geojson data
# output: dfCube.RData
print("dfcube")
createOccupancyCube(file.path(processingFilePath, "trendOccupancy"), bucket = bucket)

# create tabular data
# input: eu_concern_species.tsv/be_alientaxa_cube.csv
# output: "eu_concern_species_processed.parquet"/ "be_alientaxa_cube_processed.parquet" 
print("unionlist")
createTabularData(dataDir =  processingFilePath, type = "unionlist", bucket = bucket)
print("occurrence")
createTabularData(dataDir = processingFilePath, type = "occurrence", bucket = bucket)

###################################################
# test if all the data files needed are on bucket #
# and can be read into R                          #
###################################################
print("tests")

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


