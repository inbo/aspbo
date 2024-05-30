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
# connect_to_bucket(Sys.getenv("UAT_BUCKET"))
# get feedback ####

# test S3_bucket ####
test_that("Check S3_BUCKET env variable", {
    
    expect_false(Sys.getenv("S3_BUCKET") == "", "env S3_BUCKET is not provided")
    
  })

bucket <- paste0("s3://",Sys.getenv("S3_BUCKET"))
print(bucket)

# files that are currently in management needs to be uploaded to the bucket
directFiles <- list.files(directFilePath)

test_that("Upload direct files", {
    
    lapply(directFiles, function(fileName){
        
        put_object(file.path(directFilePath, fileName),
          object = fileName,
          bucket = bucket,
          multipart = TRUE,
          show_progress = TRUE,
          region = "eu-west-1") 
      })
    
  })

## test to see if all data on bucket

test_that("Check uploaded direct files", {
    
    bucket_df <- get_bucket_df(bucket, region = "eu-west-1") 
    expect_in( directFiles, bucket_df$Key)
    
  })
