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




