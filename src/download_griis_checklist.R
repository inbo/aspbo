# Libraries ####
library(rgbif)
library(readr)
library(dplyr)
library(magrittr)

# download using previous limit ####
current_metadata <- read_csv("data/input/griis_checklist_version.txt", 
                             col_types = cols(modified = col_character())) %>% 
  mutate(modified = parse_datetime(modified))

limit <- max(current_metadata$limit, na.rm = TRUE)
GRIIS_raw <- name_usage(datasetKey = "6d9e952f-948c-4483-9807-575348147c7e",
                        limit = limit)

# increase download limit ####
while(GRIIS_raw$meta$endOfRecords == FALSE){
  limit <- limit + 1000
  print(limit)
  GRIIS_raw <- name_usage(datasetKey = "6d9e952f-948c-4483-9807-575348147c7e",
                          limit = limit)
}

# get data ####
GRIIS_base <- GRIIS_raw$data

# update metadata ####
new_metadata <- datasets(uuid = "6d9e952f-948c-4483-9807-575348147c7e")
new_citation <- new_metadata$data$citation$identifier

current_metadata <- current_metadata %>% 
  add_row(modified = new_update,
          citation = new_citation,
          limit = limit)

# export files ####
write_csv(current_metadata, "./data/input/griis_checklist_version.txt")
write_tsv(GRIIS_base, "./data/output/data_input_checklist_indicators.tsv")