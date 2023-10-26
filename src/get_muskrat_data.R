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
                x = samplingProtocol))
  
# Add spatial component ####
gem <- st_read("./data/spatial/communes.geojson") %>% 
  st_transform(4326) %>% 
  rename(Gemeente = NAAM)

provincies <- st_read("./data/spatial/provinces.geojson") %>% 
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

# Export ####
write_csv(muskrat_data, "./data/output/muskrat_data.csv")
