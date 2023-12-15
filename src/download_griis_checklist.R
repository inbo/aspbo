# Libraries ####
library(readr)
library(dplyr)
library(magrittr)
library(stringr)
library(rgbif)

# GRIIS taxon base ####
current_metadata <- read_csv("./data/output/UAT_processing/griis_checklist_version.txt", 
                             col_types = cols(modified = col_character())) %>% 
  mutate(modified = parse_datetime(modified))

limit <- max(current_metadata$limit, na.rm = TRUE)

dataset_key <- "6d9e952f-948c-4483-9807-575348147c7e"

GRIIS_raw <- name_usage(datasetKey = dataset_key,
                        limit = limit)

GRIIS_base <- GRIIS_raw$data %>% 
  filter(rank %in% c("GENUS", "SPECIES", "SUBSPECIES", "VARIETY"))

# Additional data ####
## unzip ####
unzip("./data/input/GRIIS/dwca-unified-checklist.zip",
      exdir = "./data/input/GRIIS/dwca-unified-checklist/",
      overwrite = TRUE,
      junkpaths = TRUE)

## read csvs ####
for(f in dir(path = "./data/input/GRIIS/dwca-unified-checklist/",
             pattern = ".txt")){
  
  df_name <- paste0(gsub(pattern = ".txt",
                  replacement = "",
                  f), "_raw")
  
  df <- read_tsv(paste0("./data/input/GRIIS/dwca-unified-checklist/", f)) %>% 
    mutate(nubKey = as.integer(gsub(pattern = "https://www.gbif.org/species/",
                         replacement = "",
                         id))) %>% 
    select(-id)
  
  assign(df_name, df)
}

## Map files ####
### distribution ####
distribution <- distribution_raw %>% 
  separate(col = "eventDate",
           into = c("first_observed", "last_observed")) %>% 
  mutate(establishmentMeans = toupper(establishmentMeans),
         status = toupper(occurrenceStatus)) %>% 
  rename(country = countryCode,
         locationId = locationID,
         source_distribution = source)

### description ####
degree_of_establishment <- description_raw %>% 
  filter(type == "degree of establishment")

#### Native Range ####
Africa <- c("Africa", "Eastern Africa", "Northern Africa", "Southern Africa",
            "Western Africa", "Middle Africa")

America <- c("Americas", "Caribbean", "Central America", "Northern America",
             "South America")

Asia <- c("Asia", "Central Asia", "Eastern Asia", "Southeastern Asia",
          "Southern Asia", "Western Asia")

Europe <- c("Eastern Europe", "Europe", "Southern Europe", "Western Europe")

Oceania <- c("Australia and New Zealand", "Melanesia", "Micronesia")

native_range <- description_raw %>% 
  filter(type == "native range") %>% 
  rename("native_range" = description) %>% 
  mutate(native_continent = case_match(native_range,
                                       Africa ~ "Africa",
                                       America ~ "America",
                                       Asia ~ "Asia",
                                       Europe ~ "Europe",
                                       Oceania ~ "Oceania",
                                       .default = NA_character_)) %>% 
  distinct(nubKey, native_range, native_continent)

table(native_range$native_range, native_range$native_continent, useNA = "ifany")

no_native_continent <- native_range %>% 
  filter(is.na(native_continent),
         !is.na(native_range)) %>% 
  write_csv("./data/interim/no_native_continent.csv")

#### Pathways ####
pathways_1 <- description_raw %>% 
  filter(type == "pathway") %>% 
  separate(col = description,
           into = c("pathway_type", "description"),
           sep = ":") %>% 
  separate(col = "description",
           into = c("pathways_level1", "pathways_level2"),
           sep = "_",
           extra = "merge")

pathways_2 <- description_raw %>% 
  filter(!nubKey %in% pathways_1$nubKey) %>% 
  filter(type %in% c("introduction pathway",
                     "pathway of introduction")) %>% 
  mutate(pathway_type = NA_character_) %>% 
  separate(col = "description",
           into = c("pathways_level1", "pathways_level2"),
           sep = "_",
           extra = "merge")

pathways <- rbind(pathways_1, pathways_2)

# Combine base with additional data ####
## read template ####
old_checklist <- read_tsv("https://raw.githubusercontent.com/inbo/aspbo/f4ac68b41a5e1f9f4c76d86b6ba7957e7975213a/data/output/UAT_processing/data_input_checklist_indicators.tsv")

GRIIS_final <- GRIIS_base %>% 
  left_join(distribution, by = c("nubKey")) %>% 
  left_join(pathways, by = c("nubKey")) %>% 
  left_join(native_range, by = c("nubKey")) %>% 
  select(colnames(old_checklist))

# export files ####
write_csv(current_metadata, "./data/output/UAT_processing/griis_checklist_version.txt")
write_tsv(GRIIS_final, "./data/output/UAT_processing/data_input_checklist_indicators.tsv")
