# Libraries ####
library(rgbif)
library(readr)
library(dplyr)
library(magrittr)

# Credentials ####
gbif_email <- Sys.getenv("email")
gbif_pwd <- Sys.getenv("gbif_pwd")
gbif_user <- Sys.getenv("gbif_user")

# test update status ####
## current version ####
current_metadata <- read_csv("data/output/UAT_processing/griis_checklist_version.txt", 
                             col_types = cols(modified = col_character())) %>% 
  mutate(modified = parse_datetime(modified))

latest_update <- max(current_metadata$modified, na.rm = TRUE)

## new version ####
new_metadata <- datasets(uuid = "6d9e952f-948c-4483-9807-575348147c7e")

new_update <- parse_datetime(new_metadata$data$modified)

## Continue? ####
if(latest_update < new_update){
  print("updating GRIIS checklist")
}else{
  stop("GRIIS checklist up to date")
}
