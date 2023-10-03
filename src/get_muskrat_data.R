# Vangstoverzicht muskusrat op basis van GBIF

# packages
library(sf)
library(rgbif)
library(dplyr)
library(tidyr)

# load data
down_musk <- occ_download(
             pred("taxonKey", 5219858),
             pred_in("datasetKey", c("ddd51fa5-97ce-48ff-9a58-a09d7e76b103",
                                     "b7ee2a4d-8e10-410f-a951-a7f032678ffe",
                                     "95b0e787-8508-4247-9e48-18b45fc7d12e",
                                     "3634aee3-41d5-4aa2-8cb5-875859f62a3a",
                                     "69351197-880d-4100-8e69-e80babf3fdd7")),
             format = "SIMPLE_CSV",
             user = Sys.getenv("gbif_user"), 
             pwd = Sys.getenv("gbif_pwd"), 
             email = Sys.getenv("email"))

occ_download_wait(down_musk,
                  curlopts = list(verbose = TRUE,
                                  http_version = 2,
                                  forbid_reuse = TRUE))

d <- occ_download_get(down_musk) %>%
  occ_download_import()

gem <- st_read("./data/spatial/communes.geojson") %>% 
  st_transform(4326) %>% 
  mutate(Gemeente = ifelse(is.na(NameDut), NameFre, NameDut))
gem <- st_zm(gem, drop = TRUE, what = "ZM")

provincies <- read_sf("./Input/Shapefiles/AD_4_Province.shp") %>% 
  st_transform(4326)
provincies <- st_zm(provincies, drop = TRUE, what = "ZM")

d <- st_as_sf(d, 
         coords = c("decimalLongitude", "decimalLatitude"), 
         na.fail = FALSE,
         remove = FALSE,
         crs = 4326)

d$Gemeente <- apply(sf::st_intersects(gem, 
                                  d, 
                                  sparse = FALSE), 2, 
                function(col) {gem[which(col),
                ]$Gemeente})

d$gemeente <- NA 

for(i in 1:length(d$Gemeente)){
  d$gemeente[i] <- as.character(d$Gemeente[[i]][1])
}

# Aanvullen West-Vlaamse data die nog niet op GBIF staat: AanvullenGBIF.R
d <- d %>% 
  add_row(WV)


# Analyses

## Evolutie vangsten
catches_year <- d %>%
  filter(stateProvince %in% c("West Flanders", "East Flanders", 
                              "Flemish Brabant", "Antwerp", "Limburg")) %>%
  filter(year < 2023) %>% 
  group_by(year, stateProvince) %>%
  summarise(catches = sum(individualCount, na.rm = TRUE))

ggplot(catches_year, 
       aes(x = year, y = catches, fill = stateProvince)) +
  geom_bar(position = "stack", 
           stat = "identity") +
  facet_zoom(xy = year > 2008, 
             horizontal = FALSE, 
             zoom.size = 1.5,
             zoom.data = ifelse(year>2008, NA, FALSE)) +
  labs(x = "Jaar", y = "Vangsten") +
  scale_fill_discrete(name = "Provincie", labels = c("Antwerpen",
                                                     "Oost-Vlaanderen", 
                                                     "Vlaams-Brabant", 
                                                     "Limburg", 
                                                     "West-Vlaanderen"))


## Vangsten per gemeente 2022
catches_gem <- d %>%
  group_by(year, gemeente, .drop=FALSE) %>%
  summarise(catches = sum(individualCount, na.rm = TRUE)) %>% 
  st_drop_geometry()

VL_Gem <- gem %>% 
  filter(LanguageSt %in% c(1, 5)) %>% 
  select(gemeente = NameDut) %>% 
  mutate(year = 2022,
         catches = 0) %>% 
  st_drop_geometry()

catches_gem_2022 <- catches_gem %>% 
  filter(year == 2022) %>%
  ungroup() %>% 
  add_row(VL_Gem) %>% 
  group_by(year, gemeente) %>% 
  summarise(catches = sum(catches, na.rm = TRUE))

data <- gem %>% 
  left_join(catches_gem_2022, 
            by = c("Gemeente" = "gemeente"))

pal <- colorBin(palette = rev(heat.colors(11)), 
                bins = c(-Inf,0.0001,5,10,25,50,100,+Inf),
                na.color="#cecece")

leaflet(data, options = leafletOptions(minZoom = 7, maxZoom = 10)) %>%
  addTiles() %>% 
  addLegend(title = paste("Gevangen muskusratten 2022"),
            pal = pal, values = ~catches, 
            position = "bottomleft") %>%
  addPolygons(color = ~ pal(catches), 
              stroke = FALSE, smoothFactor = 0.2, fillOpacity = 0.85,
              popup=sprintf("<strong>%s</strong><br>%s",
                            data$Gemeente, data$catches)) %>%
  addPolylines(weight = 1.5, color = "white") %>%
  setView(4.2813167, 50.76, zoom = 8) %>% 
  addPolygons(data = provincies, group = "Provincies", fill = NA,
              color = "forestgreen", weight = 2)

# Welke gemeenten liggen aan de grens?
Wal <- c("Voeren", "Riemst", "Mesen", "Ieper", "Zonnebeke", "Wervik", "Menen", 
         "Kortrijk", "Spierre-Helkijn", "Avelgem", "Kluisbergen", "Ronse", 
         "Maarkedal", "Brakel", "Geraardsbergen", "Bever", "Herne", "Pepingen", 
         "Halle", "Beersel", "Sint-Genesius-Rode", "Hoeilaart", "Overijse", 
         "Huldenberg", "Oud-Heverlee", "Bierbeek", "Boutersem", "Hoegaarden", 
         "Tienen", "Landen", "Gingelom", "Heers", "Tongeren", "Herstappe")
Fran <- c("De Panne", "Veurne", "Alveringem", "Poperinge", "Heuvelland")
Ned <- c("Lanaken", "Maasmechelen", "Dilsen-Stokkem", "Maaseik", "Kinrooi", 
         "Bree", "Bocholt", "Hamont-Achel", "Neerpelt", "Lommel", "Mol", 
         "Arendonk", "Ravels", "Turnhout", "Baarle-Hertog", "Merksplas", 
         "Hoogstraten", "Wuustwezel", "Kalmthout", "Essen", "Kapellen", 
         "Stabroek", "Antwerpen", "Beveren", "Sint-Gillis-Waas", "Stekene", 
         "Moerbeke", "Wachtebeke","Zelzate", "Assenede", "Sint-Laureins", 
         "Maldegem", "Damme", "Knokke-Heist")

stap1 <- catches_gem %>%  
  mutate(Grens =  ifelse(gemeente %in% Wal, "Wal", "Nee")) %>%
  mutate(Grens =  ifelse(gemeente %in% Fran, "Fran", Grens)) %>%
  mutate(Grens =  ifelse(gemeente %in% Ned, "Ned", Grens))

stap1 %>% 
  filter(year > 2009 & year < 2023) %>% 
  group_by(year, Grens) %>% 
  summarise(catches = sum(catches, na.rm = TRUE)) %>% 
  ggplot(aes(x = year, y = catches)) +
  geom_point(aes(color = Grens)) +
  geom_line(aes(color = Grens)) +
  scale_x_continuous(breaks = 2010:2022) +
  labs(x = "Jaar", y = "Vangsten") +
  scale_color_discrete(name = "Gemeente grenst aan:", labels = c("Frankrijk",
                                                     "Nederland", 
                                                     "Geen grensgemeente", 
                                                     "Wallonië"))
# Evolutie vangsten op kaart
# Opgelet!!! Deze nulwaarden zijn assumpties zeker voor jaren voor 2016
VL_Gem_ext <- expand.grid(VL_Gem$gemeente, c(1991:2022)) %>% 
  mutate(catches = 0) %>% 
  rename(gemeente = Var1,
         year = Var2)

catches_gem_full <- catches_gem %>%
  ungroup() %>% 
  add_row(VL_Gem_ext) %>% 
  group_by(year, gemeente) %>% 
  summarise(catches = sum(catches, na.rm = TRUE)) %>% 
  ungroup() %>% 
  arrange(gemeente, year) %>% 
  mutate(prev_catch = lag(catches)) %>% 
  mutate(change = catches - prev_catch)


data <- catches_gem_full %>%
  filter(year == 2022) %>% 
  left_join(gem, 
            by = c("gemeente" = "Gemeente"))

data <- st_as_sf(data)

pal <- colorBin(palette = "PiYG", 
                bins = c(-Inf,-100,-50,-25,-10,-5,0,5,10,25,50,100,+Inf),
                na.color="#cecece",
                reverse = TRUE)

leaflet(data, options = leafletOptions(minZoom = 7, maxZoom = 10)) %>%
  addTiles() %>% 
  addLegend(title = paste("Toename / afname aantal vangsten"),
            pal = pal, values = ~change, 
            position = "bottomleft") %>%
  addPolygons(color = ~ pal(change), 
              stroke = FALSE, smoothFactor = 0.2, fillOpacity = 0.85,
              popup=sprintf("<strong>%s</strong><br>%s",
                            data$gemeente, data$change)) %>%
  addPolylines(weight = 1.5, color = "white") %>%
  setView(4.2813167, 50.76, zoom = 8) %>% 
  addPolygons(data = provincies, group = "Provincies", fill = NA,
              color = "forestgreen", weight = 2)





