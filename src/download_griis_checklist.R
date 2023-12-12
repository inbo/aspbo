# Libraries ####
library(rgbif)
library(readr)
library(dplyr)
library(magrittr)
library(stringr)

# set datasetKey ####
dataset_key <- "6d9e952f-948c-4483-9807-575348147c7e"

# download using previous limit ####
current_metadata <- read_csv("./data/output/UAT_processing/griis_checklist_version.txt", 
                             col_types = cols(modified = col_character())) %>% 
  mutate(modified = parse_datetime(modified))

limit <- max(current_metadata$limit, na.rm = TRUE)
GRIIS_raw <- name_usage(datasetKey = dataset_key,
                        limit = limit)

# increase download limit ####
while(GRIIS_raw$meta$endOfRecords == FALSE){
  limit <- limit + 1000
  print(limit)
  GRIIS_raw <- name_usage(datasetKey = dataset_key,
                          limit = limit)
}

# get data ####
# old_checklist <- read_tsv("https://raw.githubusercontent.com/inbo/aspbo/f4ac68b41a5e1f9f4c76d86b6ba7957e7975213a/data/output/UAT_processing/data_input_checklist_indicators.tsv")
# 
# test <- old_checklist %>% 
#   distinct(nubKey, habitat) %>% 
#   group_by(nubKey) %>% 
#   add_tally()
## Base ####
GRIIS_base <- GRIIS_raw$data %>% 
  filter(rank %in% c("GENUS", "SPECIES", "SUBSPECIES", "VARIETY"))

## speciesProfiles ####
speciesProfiles <- data.frame()

for(i in unique(GRIIS_base$nubKey)){
  indv_speciesProfiles_list <- name_usage(key = i,
                                          data = "speciesProfiles")
  
  
  indv_speciesProfiles <- indv_speciesProfiles_list$data
  
  if(nrow(indv_speciesProfiles) == 0){
    next
    print(paste0("No match for ", i))
  }
  
  cols_to_keep <- c("taxonKey", "source", 
                    "marine", "freshwater", "terrestrial")
  
  for(q in cols_to_keep){
    if(!q %in% colnames(indv_speciesProfiles)){
      if(q == "taxonKey"){
        next
        print(paste0("Corrupt match for ", i))
      }else{
        print(paste0("adding NA value for ", q))
        indv_speciesProfiles <- indv_speciesProfiles %>% 
          mutate(q = NA_character_) 
        
        colnames(indv_speciesProfiles) <- gsub(pattern = "q", 
                                               replacement = q,
                                               colnames(indv_speciesProfiles)) 
      }
    }
  }
  
  indv_speciesProfiles <- indv_speciesProfiles %>% 
    select(all_of(cols_to_keep))
  
  if(nrow(speciesProfiles) == 0){
    speciesProfiles <- indv_speciesProfiles
  }else{
    speciesProfiles <- rbind(speciesProfiles, indv_speciesProfiles)
  }
}

speciesProfiles_habitat <- speciesProfiles %>% 
  mutate(marine_temp = case_match(marine,
                                  "TRUE" ~ 1,
                                  "FALSE" ~ 0,
                                  .default = 0),
         freshwater_temp = case_match(freshwater,
                                      "TRUE" ~ 1,
                                      "FALSE" ~ 0,
                                      .default = 0),
         terrestrial_temp = case_match(terrestrial,
                                       "TRUE" ~ 1,
                                       "FALSE" ~ 0,
                                       .default = 0)) %>% 
  group_by(taxonKey) %>% 
  summarise(marine = max(marine_temp, na.rm = TRUE),
            freshwater = max(freshwater_temp, na.rm = TRUE),
            terrestrial = max(terrestrial_temp, na.rm = TRUE)) %>% 
  mutate(habitat_code = paste0(marine, freshwater, terrestrial)) %>% 
  mutate(habitat = case_match(habitat_code,
                              "111" ~ "marine|freshwater|terrestrial",
                              "110" ~ "marine|freshwater",
                              "101" ~ "marine|terrestrial",
                              "100" ~ "marine",
                              "011" ~ "freshwater|terrestrial",
                              "010" ~ "freshwater",
                              "001" ~ "terrestrial",
                              .default = NA_character_)) %>% 
  select(taxonKey, habitat)

speciesProfiles <- speciesProfiles %>% 
  left_join(speciesProfiles_habitat)

## Combine with base ####
GRIIS_base <- GRIIS_base %>% 
  left_join(speciesProfiles, 
            by = c("nubKey" = "taxonKey"),
            relationship  = "many-to-many")

# update metadata ####
new_metadata <- datasets(uuid = "6d9e952f-948c-4483-9807-575348147c7e")
new_citation <- new_metadata$data$citation$identifier
new_update <- as.Date(new_metadata$data$modified)

current_metadata <- current_metadata %>% 
  add_row(modified = new_update,
          citation = new_citation,
          limit = limit)

# export files ####
write_csv(current_metadata, "./data/output/UAT_processing/griis_checklist_version.txt")
write_tsv(GRIIS_base, "./data/output/UAT_processing/data_input_checklist_indicators.tsv")
