#' @author Sander Devisscher
#' 
#' @description
#' This R-script uploads the necessary files to the UAT S3 bucket to test the 
#' development evironment of the [alien species portal](*add url when UAT is live*)
#' 
#' @details 
#' This script uses `./src/connect_to_bucket.R` to generate a access token 
#' needed to access the bucket. 

# Libraries ####
library(aws.s3)
library(readr)
library(tidyr)
library(magrittr)
library(dplyr)
library(stringr)
library(alienSpecies) # for all the create* functions
library(testthat)

# filelist - prep ####
UAT_filelist <- read_csv("./data/ETL_files/UAT_filelist.csv", 
                         col_types = cols(filepath_bucket = col_character()),
                         na = "") %>% 
  mutate(filepath_bucket = str_replace_na(filepath_bucket, ""))

# connect to bucket ####
source("./src/connect_to_bucket.R")

bucket_list_before <- connect_to_bucket(bucket_name = Sys.getenv("UAT_bucket")) %>% 
  select(Key, 
         LastModified_before = LastModified, 
         Size_before = Size)

# upload files ####
for(i in 1:nrow(UAT_filelist)){
  file_local <- paste0(UAT_filelist$filepath_local[i],
                       UAT_filelist$filename_local[i])
  
  file_bucket <- paste0(UAT_filelist$filepath_bucket[i],
                        UAT_filelist$filename_bucket[i])
  
  put_object(file_local,
             object = file_bucket,
             bucket = Sys.getenv("UAT_bucket"),
             multipart = TRUE,
             show_progress = TRUE,
             region = "eu-west-1")
}

# get feedback ####
bucket_list_after <- get_bucket_df(Sys.getenv("UAT_bucket"),
                                   region = "eu-west-1") %>% 
  select(Key, 
         LastModified_after = LastModified, 
         Size_after = Size) %>% 
  full_join(bucket_list_before, by = "Key") %>% 
  mutate(size_changed = case_when(Size_before == Size_after ~ FALSE,
                                  TRUE ~ TRUE),
         Size_before = as.numeric(Size_before),
         Size_after = as.numeric(Size_after),
         size_diff = case_when(is.na(Size_before) ~ Size_after,
                               TRUE ~ Size_after - Size_before))

write_csv(bucket_list_after, "./data/ETL_files/UAT_upload_log.csv")

# test uploaded files ####
# A placeholder for a alienSpecies function to test the files on the bucket.

################################
# check presence of input data #
################################

test_that("Input data", {
  
  # management data
  expect_in( c("Oxyura_jamaicensis.csv",  "Lithobates_catesbeianus.csv", "Ondatra_zibethicus.csv"), dir("./data/input/management"))
  
  # grid data
  expect_gte(length(dir("./data/input/grid")),1)
  
  # vespa velutina shape
  expect_gte(length(dir("./data/input/Vespa_velutina_shape")),1)
  
  # occurreneCube
  expect_gte(length(dir("./data/input/occurrenceCube")),1)
  
  #provinces.geojson
  expect_true(file.exists("./data/spatial/provinces.geojson"))
  
  #communes.geojson
  expect_true(file.exists("./data/spatial/communes.geojson"))
  
  expect_true(file.exists("./data/input/be_alientaxa_info.csv"))
 
  expect_true(file.exists("./data/input/df_timeseries.tsv"))
  
  expect_true(file.exists("./data/input/data_input_checklist_indicators.tsv"))
  
  expect_true(file.exists( "./data/input/eu_concern_species.tsv"))
  
  expect_true(file.exists("./data/input/be_alientaxa_cube.csv"))
  })






###############################################################
## The following create* function will take input data, 
## process it and put them on s3 bucket 
## Connection to S3 bucket should be in place by this point
###############################################################

# input: folder grid containing gewestbel shape data
# output: grid.RData 
createShapeData(dataDir = "./data/input/grid")

# input Vespa_velutina_shape" folder containing shape data
# output: Vespa_velutina_shape.RData
createShapeData(dataDir = "./data/input/Vespa_velutina_shape")

# input: folder occurrenceCube containing be_1km and be_20 km shape data
# output: occurrenceCube.RData
createShapeData(dataDir = "./data/input/occurrenceCube")

# output: provinces.RData
createShapeData(dataDir = "./data/spatial/provinces.geojson")

# output: communes.RData
createShapeData(dataDir = "./data/spatial/communes.geojson")

# create key data
# input:  "be_alientaxa_info.csv"
# output: "keys.csv"
createKeyData(dataDir = "./data/input")

# create time series data
# input:  "df_timeseries.tsv" and "grid.RData" from bucket
# note: due to the size of "df_timeseries.tsv", it's not tracked, user needs to provide the parent folder to "df_timeseries.tsv".
# output: full_timeseries.RData

createTimeseries(
  dataDir = "/data/input", 
  shapeData = loadShapeData("grid.RData")$utm1_bel_with_regions
)

# create occupancy cube 

# input: trendOccupancy folder containing T1* and ias_belgium_t0_2016/18/20 geojson data
# output: dfCube.RData
createOccupancyCube()

# create tabular data
# input: data_input_checklist_indicators.tsv/eu_concern_species.tsv/be_alientaxa_cube.csv
# output: "eu_concern_species_processed.RData"/"data_input_checklist_indicators_processed.RData"/ "be_alientaxa_cube_processed.RData" 

createTabularData(dataDir =  "./data/input", type = "indicators")
createTabularData(dataDir =  "./data/input", type = "unionlist")
createTabularData(dataDir =  "./data/input", type = "occurrence")


# files that are currently in management needs to be uploaded to the bucket

bucket <-  Sys.getenv("UAT_bucket")
#  bucket <- config::get("bucket", file = system.file("config.yml", package = "alienSpecies"))

lapply(c("Oxyura_jamaicensis.csv",  "Lithobates_catesbeianus.csv", "Ondatra_zibethicus.csv"), function(fileName){
  
  put_object(file.path("./data/input", fileName),
             object = fileName,
             bucket = bucket,
             region = "eu-west-1") 
})


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



test_that("Load exotenData", {
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


test_that("management data", {
  
  expect_in( c("Oxyura_jamaicensis.csv",  "Lithobates_catesbeianus.csv", "Vespa_velutina_shape.RData", "Ondatra_zibethicus.csv"), tmpTable$Key)
  
})






