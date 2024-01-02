#' @author Yingjie Zhang
#' 
#' @description
#' This R-script uploads data files that do not need processing
#' @details 
#' This script uses `./src/connect_to_bucket.R` to generate a access token 
#' needed to access the bucket. 

# Libraries ####
print("libraries")
library(aws.s3)
library(testthat)

directFilePath <- "./data/output/UAT_direct"

# connect to bucket ####
# run this code when you run this script locally
# print("source connect_to_bucket.R")
# source("./src/connect_to_bucket.R")

# get feedback ####

bucket <-  Sys.getenv("S3_bucket")
#  bucket <- config::get("bucket", file = system.file("config.yml", package = "alienSpecies"))

print("get_bucket_df")
bucket_df <- get_bucket_df(bucket, region = "eu-west-1") 
# test uploaded files ####
# A placeholder for a alienSpecies function to test the files on the bucket.


# files that are currently in management needs to be uploaded to the bucket
directFiles <- c("Oxyura_jamaicensis.csv",  "Lithobates_catesbeianus.csv", "Ondatra_zibethicus.csv", "translations.csv")
print("lapply put_object")
lapply(directFiles, function(fileName){
  
  put_object(file.path(directFilePath, fileName),
             object = fileName,
             bucket = bucket,
             multipart = TRUE,
             show_progress = TRUE,
             region = "eu-west-1") 
})


## test to see if all data on bucket

test_that("management data", {
  
  expect_in( directFiles, bucket_df$Key)
  
})
