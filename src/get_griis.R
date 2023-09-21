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
current_metadata <- read_csv("data/input/griis_checklist_version.txt", 
                             col_types = cols(modified = col_character())) %>% 
  mutate(modified = parse_datetime(modified))

latest_update <- max(current_metadata$modified, na.rm = TRUE)

## new version ####
new_metadata <- datasets(uuid = "6d9e952f-948c-4483-9807-575348147c7e")

new_update <- parse_datetime(new_metadata$data$modified)

## Download new version ####
if(latest_update < new_update){
  limit <- max(current_metadata$limit, na.rm = TRUE)
  GRIIS_raw <- name_usage(datasetKey = "6d9e952f-948c-4483-9807-575348147c7e",
                          limit = limit)
  
  while(GRIIS_raw$meta$endOfRecords == FALSE){
    limit <- limit + 1000
    print(limit)
    GRIIS_raw <- name_usage(datasetKey = "6d9e952f-948c-4483-9807-575348147c7e",
                            limit = limit)
  }
  
  GRIIS__base <- GRIIS_raw$data
  
  new_citation <- new_metadata$data$citation$identifier
  
  current_metadata <- current_metadata %>% 
    add_row(modified = new_update,
            citation = new_citation,
            limit = limit)
  
  write_csv(current_metadata, "./data/input/griis_checklist_version.txt")
  write_tsv(GRIIS_raw, "./data/output/data_input_checklist_indicators.tsv")
}
