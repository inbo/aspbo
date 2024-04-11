# Libraries ####
library(readr)
library(magrittr)
library(dplyr)
library(aws.s3)
library(rgbif)
library(alienSpecies)

# connect to bucket ####
source("./src/connect_to_bucket.R")

#UAT_filelist <- connect_to_bucket(bucket_name = Sys.getenv("UAT_bucket"))

# get files ####
eu_concern_list_old <- loadTabularData(type = "unionlist") %>% 
  rename(checklist_scientificName = scientificName,
         backbone_taxonKey = taxonKey) 


eu_concern_list_new <- name_usage(datasetKey = "79d65658-526c-4c78-9d24-1870d67f8439",
                                  limit = 1000)

eu_concern_list_new <- eu_concern_list_new$data

# fix known issues ####
## Vespa velutina nigrithorax: subspp -> spp 
eu_concern_list_new <- eu_concern_list_new %>% 
  filter(rank != "KINGDOM",
         taxonomicStatus == "ACCEPTED") %>% 
  mutate(backbone_taxonKey = case_when(canonicalName == "Vespa velutina nigrithorax" 
                                       & nubKey == 6247411 ~ 1311477,
                                       canonicalName == "Salvinia molesta" 
                                       & nubKey == 5274863 ~ 5274861,
                                       TRUE ~ nubKey),
         checklist_scientificName = case_when(!is.na(species) ~ species,
                                              TRUE ~ canonicalName)) %>% 
  select(checklist_scientificName,
         english_name = vernacularName,
         checklist_kingdom = parent,
         backbone_taxonKey,
         backbone_taxonomicStatus = taxonomicStatus) %>% 
  arrange(checklist_scientificName)

if(nrow(eu_concern_list_new) > nrow(eu_concern_list_old)){
  ## list has expanded ####
  # write new list to output to trigger upload
  write_tsv(eu_concern_list_new, "./data/output/UAT_processing/eu_concern_species.tsv")
}else{
  ## list has not expanded ####
  new_taxonKeys <- subset(eu_concern_list_new$backbone_taxonKey,
                          !eu_concern_list_new$backbone_taxonKey %in% 
                            eu_concern_list_old$backbone_taxonKey)
  
  lists_combined <- eu_concern_list_new %>% 
    full_join(eu_concern_list_old, by= "checklist_scientificName")
  
  changed_taxonKeys <- lists_combined %>% 
    filter(!is.na(backbone_taxonKey.x),
           !is.na(backbone_taxonKey.y)) %>% 
    filter(backbone_taxonKey.x != backbone_taxonKey.y)
  
  omited_taxonKeys <- lists_combined %>% 
    filter(is.na(backbone_taxonKey.x))
  
  if(length(new_taxonKeys) > 0 | 
     nrow(changed_taxonKeys) > 0 |
     nrow(omited_taxonKeys) > 0){
    ### list has changed ####
    # write new list to output to trigger upload
    write_tsv(eu_concern_list_new, "./data/output/UAT_processing/eu_concern_species.tsv")
  }else{
    ### No changes ####
    warning("no changes detected! eu concern list not updated!")
  }
}
