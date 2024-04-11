library(knitr)

# create temporary R file ####
tempR <- tempfile(fileext = ".R")
knitr::purl("https://raw.githubusercontent.com/trias-project/indicators/main/src/01_get_data_input_checklist_indicators.Rmd", output=tempR)
source(tempR)
unlink(tempR)

# move file to UAT_processing ####
file.copy(from = "./data/interim/data_input_checklist_indicators.tsv",
          to = "./data/output/UAT_processing/data_input_checklist_indicators.tsv",
          overwrite = TRUE)

file.remove("./data/interim/data_input_checklist_indicators.tsv")

# add vernicular names
checklist_raw <- read_delim("data/output/UAT_processing/data_input_checklist_indicators.tsv", 
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
  temp_name_usage <- name_usage(key = t, data = "vernacularNames")
  spec_vernicular_names <- temp_name_usage$data 
  
  if(nrow(spec_vernicular_names) > 0){
    spec_vernicular_names <- spec_vernicular_names %>% 
      filter(language %in% c("eng", "fra", "nld")) %>% 
      mutate(vernacularName = str_to_sentence(vernacularName),
             language = str_sub(language, 0, 2)) %>% 
      distinct(taxonKey, language, vernacularName) %>% 
      group_by(language, taxonKey) %>% 
      summarise(vernacular_name = paste(vernacularName, collapse = ", ")) %>% 
      ungroup() %>% 
      pivot_wider(id_cols = taxonKey,
                  names_from = language,
                  names_prefix = "vernacular_name_",
                  values_from = vernacular_name)
    
    if(nrow(all_vernicular_names) == 0){
      all_vernicular_names <- spec_vernicular_names
    }else{
      all_vernicular_names <- bind_rows(all_vernicular_names, spec_vernicular_names)
    }
  }else{
    warning(paste0("No vernicular names for ", t))
  }
}

checklist <- checklist_raw %>% 
  left_join(all_vernicular_names, by = c("nubKey" = "taxonKey")) %>% 
  write_delim("data/output/UAT_processing/data_input_checklist_indicators.tsv", 
              delim = "\t")

