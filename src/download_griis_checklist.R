library(knitr)
library(magrittr)

# run step 1 of Trias workflow ####
tempR <- tempfile(fileext = ".R")
knitr::purl("https://raw.githubusercontent.com/trias-project/indicators/main/src/01_get_data_input_checklist_indicators.Rmd", output=tempR)
source(tempR)
unlink(tempR)

# The structure as presented by Trias is slightly different from the structure 
# of this repository. Therefore, we need to move the file to the correct location.
# move file from Trias to UAT_processing ####
file.copy(from = "./data/interim/data_input_checklist_indicators.tsv",
          to = "./data/output/UAT_processing/data_input_checklist_indicators.tsv",
          overwrite = TRUE)

file.remove("./data/interim/data_input_checklist_indicators.tsv")

# add vernicular names ####
checklist_raw <- readr::read_delim("data/output/UAT_processing/data_input_checklist_indicators.tsv", 
                                   delim = "\t", escape_double = FALSE, 
                                   trim_ws = TRUE)

taxon_keys <- unique(checklist_raw$nubKey)

all_vernicular_names <- data.frame(
  taxonKey = numeric(),
  vernacular_name_nl = character(),
  vernacular_name_fr = character(),
  vernacular_name_en = character(),
  stringsAsFactors = FALSE
)

for(t in taxon_keys){
  temp_name_usage <- rgbif::name_usage(key = t, data = "vernacularNames")
  spec_vernicular_names <- temp_name_usage$data 
  
  if(nrow(spec_vernicular_names) > 0){
    spec_vernicular_names <- spec_vernicular_names %>% 
      dplyr::filter(language %in% c("eng", "fra", "nld")) %>% 
      dplyr::mutate(vernacularName = stringr::str_to_sentence(vernacularName),
                    language = stringr::str_sub(language, 0, 2)) %>% 
      dplyr::distinct(taxonKey, language, vernacularName) %>% 
      dplyr::group_by(language, taxonKey) %>% 
      dplyr::summarise(vernacular_name = paste(vernacularName, collapse = ", ")) %>% 
      dplyr::ungroup() %>% 
      tidyr::pivot_wider(id_cols = taxonKey,
                         names_from = language,
                         names_prefix = "vernacular_name_",
                         values_from = vernacular_name)
    
    if(nrow(all_vernicular_names) == 0){
      all_vernicular_names <- spec_vernicular_names
    }else{
      all_vernicular_names <- dplyr::bind_rows(all_vernicular_names, spec_vernicular_names)
    }
  }else{
    warning(paste0("No vernicular names for ", t))
  }
}

missing_scientific_names <- checklist_raw %>% 
  dplyr::filter(is.na(species)) 

if(nrow(missing_scientific_names) > 0){
  checklist_raw <- checklist_raw %>% 
    dplyr::mutate(species = dplyr::case_when(is.na(species) ~ canonicalName,
                                             TRUE ~ species))
  
  missing_scientific_names_recheck <- checklist_raw %>% 
    dplyr::filter(is.na(species)) 
  
  if(nrow(missing_scientific_names_recheck) > 0){
    stop(paste0("After the fix these taxa are still missing their scientific names: ", paste(missing_scientific_names_recheck$nubKey, collapse = ", ")))
  }
}

# Recalculate the last observation year ####
# Sometimes the last observation year on the GRIIS checklist is not the same as 
# the last observation year in the occurrence data. This is because the GRIIS
# checklist is not updated in real-time. Therefore, we need to recalculate the
# last observation year based on the occurrence data.

## Connect to the bucket ####
Sys.setenv("AWS_DEFAULT_REGION" = "eu-west-1")

if(Sys.getenv("S3_BUCKET") != ""){
  UAT_bucket <- Sys.getenv("S3_BUCKET")
}else{
  UAT_bucket <- Sys.getenv("UAT_bucket")
}

if(Sys.getenv("amiabot") != "yes"){
  print("Executor of the script is a human >> connecting to bucket")
  source("./src/connect_to_bucket.R")
  connect_to_bucket(bucket_name = UAT_bucket)
}

## Get occurrence data from bucket ####
occurrence_data <- alienSpecies::loadTabularData(type = "occurrence") %>% 
  dplyr::group_by(taxonKey) %>%
  dplyr::summarise(last_observed_recalc = max(year, na.rm = TRUE),
            isFlanders = any(isFlanders),
            isWallonia = any(isWallonia),
            isBrussels = any(isBrussels),
            isBelgium = TRUE) %>% 
  dplyr::ungroup() %>% 
  tidyr::pivot_longer(cols = c(isFlanders, isWallonia, isBrussels, isBelgium), names_to = "region", values_to = "isRegion") %>% 
  dplyr::filter(isRegion) %>% 
  dplyr::select(-isRegion) %>% 
  dplyr::mutate(region = dplyr::case_match(region,
                             "isFlanders" ~ "Flemish Region",
                             "isWallonia" ~ "Walloon Region",
                             "isBrussels" ~ "Brussels-Capital Region",
                             "isBelgium" ~ "Belgium"))

# Write to file ####
checklist <- checklist_raw %>% 
  dplyr::left_join(all_vernicular_names, by = c("nubKey" = "taxonKey")) %>% 
  dplyr::left_join(occurrence_data, by = c("nubKey" = "taxonKey", "locality" = "region")) %>%
  dplyr::mutate(last_observed = dplyr::case_when(is.na(last_observed) ~ last_observed_recalc,
                                                 last_observed_recalc > last_observed ~ last_observed_recalc,
                                                 TRUE ~ last_observed)) %>%
  readr::write_delim("data/output/UAT_processing/data_input_checklist_indicators.tsv", 
                     delim = "\t")

