library(knitr)
library(magrittr)

# create temporary R file ####
tempR <- tempfile(fileext = ".R")
knitr::purl("https://raw.githubusercontent.com/trias-project/indicators/137-addupdate-rationale-to-calculate-the-ermerging-status-for-natura2000-sites-for-each-region-separately/src/01_get_data_input_checklist_indicators.Rmd", output=tempR)
source(tempR)
unlink(tempR)

# move file to UAT_processing ####
file.copy(from = "./data/interim/data_input_checklist_indicators.tsv",
          to = "./data/output/UAT_processing/data_input_checklist_indicators.tsv",
          overwrite = TRUE)

file.remove("./data/interim/data_input_checklist_indicators.tsv")

# add vernicular names
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

checklist <- checklist_raw %>% 
  dplyr::left_join(all_vernicular_names, by = c("nubKey" = "taxonKey")) %>% 
  readr::write_delim("data/output/UAT_processing/data_input_checklist_indicators.tsv", 
              delim = "\t")

