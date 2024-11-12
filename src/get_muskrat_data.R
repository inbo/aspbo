# Vangstoverzicht muskusrat op basis van GBIF

# Libraries ####
library(sf)
library(rgbif)
library(dplyr)
library(tidyr)
library(readr)

# Download data ####
down_musk <- occ_download(
  pred("taxonKey", 5219858),
  pred_in("datasetKey", c("ddd51fa5-97ce-48ff-9a58-a09d7e76b103",
                          "b7ee2a4d-8e10-410f-a951-a7f032678ffe",
                          "95b0e787-8508-4247-9e48-18b45fc7d12e",
                          "3634aee3-41d5-4aa2-8cb5-875859f62a3a",
                          "69351197-880d-4100-8e69-e80babf3fdd7")),
  format = "DWCA",
  user = Sys.getenv("gbif_user"), 
  pwd = Sys.getenv("gbif_pwd"), 
  email = Sys.getenv("email"))

occ_download_wait(down_musk,
                  curlopts = list(verbose = TRUE,
                                  http_version = 2,
                                  forbid_reuse = TRUE))
## Use manual download ####
# down_musk <- "0026587-231002084531237"

raw_muskrat_data <- occ_download_get(down_musk) %>%
  occ_download_import()

# Clean data ####
table(raw_muskrat_data$datasetName, 
      raw_muskrat_data$samplingProtocol, 
      useNA = "ifany")

muskrat_data_redux <- raw_muskrat_data %>% 
  filter(samplingProtocol != "casual observation",
         !grepl(pattern = "material lost/broken",
                x = samplingProtocol)) %>% 
  filter(!is.na(individualCount))

# Add spatial component ####
gem <- st_read("./data/output/UAT_processing/communes.geojson") %>% 
  st_transform(4326) %>% 
  rename(Gemeente = NAAM)

provincies <- st_read("./data/output/UAT_processing/provinces.geojson") %>% 
  st_transform(4326)

muskrat_data <- st_as_sf(muskrat_data_redux, 
                         coords = c("decimalLongitude", "decimalLatitude"), 
                         na.fail = FALSE,
                         remove = FALSE,
                         crs = 4326)

muskrat_data$Gemeente <- apply(sf::st_intersects(gem, 
                                                 muskrat_data, 
                                                 sparse = FALSE), 2, 
                               function(col) {gem[which(col),
                               ]$Gemeente})

muskrat_data$gemeente <- NA 

for(i in 1:length(muskrat_data$Gemeente)){
  muskrat_data$gemeente[i] <- as.character(muskrat_data$Gemeente[[i]][1])
}

muskrat_data$Provincie <- apply(sf::st_intersects(provincies, 
                                                  muskrat_data, 
                                                  sparse = FALSE), 2, 
                                function(col) {provincies[which(col),
                                ]$NAAM})

muskrat_data$provincie <- NA 

for(i in 1:length(muskrat_data$Gemeente)){
  muskrat_data$provincie[i] <- as.character(muskrat_data$Provincie[[i]][1])
}

testthat::expect_length(muskrat_data$provincie, nrow(muskrat_data))

# maintain needed columns ####
muskrat_data <- muskrat_data %>% 
  mutate(provincie = case_when(is.na(provincie) & gemeente == "Maldegem" ~ "Oost-Vlaanderen",
                               is.na(provincie) & gemeente == "Frasnes-Lez-Anvaing" ~ "Henegouwen",
                               is.na(provincie) & gemeente == "Zulte" ~ "Oost-Vlaanderen",
                               is.na(provincie) & gemeente == "Wortegem-Petegem" ~ "Oost-Vlaanderen",
                               is.na(provincie) & gemeente == "Geraardsbergen" ~ "Oost-Vlaanderen",
                               is.na(provincie) & gemeente == "Ronse" ~ "Oost-Vlaanderen",
                               is.na(provincie) & gemeente == "Sint-Laureins" ~ "Oost-Vlaanderen",
                               is.na(provincie) & gemeente == "Kortrijk" ~ "West-Vlaanderen",
                               is.na(provincie) & gemeente == "Damme" ~ "West-Vlaanderen",
                               is.na(provincie) & gemeente == "Hoegaarden" ~ "Vlaams-Brabant",
                               is.na(provincie) & gemeente == "Graven" ~ "Waals-Brabant",
                               is.na(provincie) & gemeente == "Poperinge" ~ "West-Vlaanderen",
                               is.na(provincie) & gemeente == "Huldenberg" ~ "Vlaams-Brabant",
                               is.na(provincie) & gemeente == "Wervik" ~ "West-Vlaanderen",
                               is.na(provincie) & gemeente == "Avelgem" ~ "West-Vlaanderen",
                               is.na(provincie) & gemeente == "Spiere-Helkijn" ~ "West-Vlaanderen",
                               is.na(provincie) & gemeente == "Overijse" ~ "Vlaams-Brabant",
                               is.na(provincie) & gemeente == "Waver" ~ "Waals-Brabant",
                               is.na(provincie) & gemeente == "Edingen" ~ "Henegouwen",
                               TRUE ~ provincie)) %>%
  left_join(provincies %>% 
              as.data.frame() %>% 
              select(NAAM, GEWEST), 
            by = c("provincie" = "NAAM")) %>% 
  select(year,
         individualCount,
         gemeente,
         provincie,
         gewest = GEWEST,
         gbifID,
         decimalLatitude,
         decimalLongitude)

# Check ####
table(muskrat_data$gewest, useNA = "ifany")
table(muskrat_data$provincie, useNA = "ifany")
table(muskrat_data$gemeente, useNA = "ifany")

## Missing provinces ####
### All ####
missing_provinces <- muskrat_data %>% 
  filter(is.na(provincie))

### With gemeente ####
# These cases are fixed in the previous step. 
# If new cases arise they should be added in the previous step.
missing_provinces_gem <- missing_provinces %>% 
  filter(!is.na(gemeente)) %>% 
  distinct(gemeente)

if(nrow(missing_provinces_gem) > 0){
  write_csv(missing_provinces_gem, "./data/interim/muskrat_missing_provinces_gem.csv")
}else{
  message("No missing provinces with gemeente")
  file.remove("./data/interim/muskrat_missing_provinces_gem.csv")
}

### Without gemeente but with geometry ####
missing_provinces_geom <- missing_provinces %>% 
  filter(is.na(gemeente) & !is.na(geometry)) %>% 
  distinct(geometry, gbifID) %>% 
  st_buffer(30)

#### intersect again with gemeentes ####
missing_provinces_geom$Gemeente <- apply(sf::st_intersects(gem, 
                                                           missing_provinces_geom, 
                                                           sparse = FALSE), 2, 
                                         function(col) {gem[which(col),
                                         ]$Gemeente})

missing_provinces_geom$gemeente <- NA 

for(i in 1:length(missing_provinces_geom$Gemeente)){
  missing_provinces_geom$gemeente[i] <- as.character(missing_provinces_geom$Gemeente[[i]][1])
}

missing_provinces_geom$Provincie <- apply(sf::st_intersects(provincies, 
                                                            missing_provinces_geom, 
                                                            sparse = FALSE), 2,
                                          function(col) {provincies[which(col),
                                          ]$NAAM})

missing_provinces_geom$provincie <- NA 

for(i in 1:length(missing_provinces_geom$Provincie)){
  missing_provinces_geom$provincie[i] <- as.character(missing_provinces_geom$Provincie[[i]][1])
}

missing_provinces_geom <- missing_provinces_geom %>% 
  left_join(provincies %>% 
              as.data.frame() %>% 
              select(NAAM, GEWEST), 
            by = c("provincie" = "NAAM")) %>% 
  st_drop_geometry() %>%
  select(gemeente_new = gemeente,
         provincie_new = provincie,
         gewest_new = GEWEST,
         gbifID) %>% 
  filter(!is.na(gemeente_new)) 

dupli_missing_provinces_geom <- missing_provinces_geom %>% 
  group_by(gbifID) %>% 
  summarise(n = n()) %>% 
  filter(n > 1)

#### readd information to muskrat_data ####
muskrat_data <- muskrat_data %>% 
  left_join(missing_provinces_geom, by = "gbifID") %>% 
  mutate(gemeente = coalesce(gemeente, gemeente_new),
         provincie = coalesce(provincie, provincie_new),
         gewest = coalesce(gewest, gewest_new)) %>% 
  select(-gemeente_new, -provincie_new, -gewest_new)

missing_provinces_final <- muskrat_data %>% 
  filter(is.na(provincie))

leaflet::leaflet(missing_provinces_final) %>% 
  leaflet::addTiles() %>% 
  leaflet::addCircles()

if(nrow(missing_provinces_final) > 0){
  write_csv(missing_provinces_final, "./data/interim/muskrat_missing_provinces_final.csv")
}else{
  message("No missing provinces with geometry")
  file.remove("./data/interim/muskrat_missing_provinces_final.csv")
}

muskrat_data <- muskrat_data %>% 
  mutate(provincie = case_when(is.na(provincie) ~ "unknown",
                                TRUE ~ provincie),
         gemeente = case_when(is.na(gemeente) ~ "unknown",
                              TRUE ~ gemeente),
         gewest = case_when(is.na(gewest) ~ "unknown",
                            TRUE ~ gewest))

# Export ####
write_csv(muskrat_data, "./data/output/UAT_direct/Ondatra_zibethicus.csv")
