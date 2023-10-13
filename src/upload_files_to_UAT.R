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

# filelist - prep ####
UAT_filelist <- read_csv("./data/filelists/UAT_filelist.csv", 
                         col_types = cols(filepath_bucket = col_character()),
                         na = "") %>% 
  mutate(filepath_bucket = str_replace_na(filepath_bucket, ""))

# connect to bucket ####
source("./src/connect_to_bucket.R")

connect_to_bucket(bucket_name = Sys.getenv("UAT_bucket"))

# get state of bucket before upload ####
# To get feedback on upload succes/failure
bucket_list_before <- get_bucket_df(Sys.getenv("UAT_bucket"))

# upload files ####
for(i in 1:nrow(UAT_filelist)){
  file_local <- paste0(UAT_filelist$filepath_local[i],
                       UAT_filelist$filename_local[i])
  
  file_bucket <- paste0(UAT_filelist$filepath_bucket[i],
                        UAT_filelist$filename_bucket[i])
  
  put_object(file,é
             object = filelist$uat_key[i],
             bucket = bucket,
             multipart = TRUE,
             show_progress = TRUE)
}