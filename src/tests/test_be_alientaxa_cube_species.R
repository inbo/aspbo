#-------------------------------------------------------------------------
#Load necessary packages and install them when this has not been done before
#-------------------------------------------------------------------------

packages <- c("testthat","utils","readr", "dplyr","sf", "rgbif", "wk", "lubridate")

for(i in packages) {
  if( ! i %in% rownames(installed.packages()) ) { install.packages( i ) }
  library(i, character.only = TRUE)
}



#-------------------------------------------------------------------------
#Load the be_alientaxa_cube, GRIIS checklist, and shapefile of Belgium
#-------------------------------------------------------------------------
be_alientaxa_cube <- read_csv(
  file = "https://zenodo.org/records/10527772/files/be_alientaxa_cube.csv?download=1",
  col_types = cols(
    year = col_double(),
    eea_cell_code = col_character(),
    taxonKey = col_double(),
    n = col_double(),
    min_coord_uncertainty = col_double()
  ),
  na = ""
)

data_file <- here::here(
  "data",
  "output",
  "UAT_processing",
  "data_input_checklist_indicators.tsv")

GRIIS <-read_tsv(data_file,
                 na = "",
                 guess_max = 5000)

#Filter GRIIS checklist, species needs to belong to kingdom plantae or animalia
GRIIS <-GRIIS %>%
  filter(locationId == "ISO_3166:BE")%>%
  filter(kingdom=="Animalia" | kingdom=="Plantae")




#read in shapefile of belgium
belgium<- sf::read_sf(dsn = "./data/output/UAT_processing/grid/", layer = "gewestbel")

#Merge different multipolygons into one big multipolygon
belgium$groep<-"belgium"
belgium<- belgium %>% 
  group_by(groep) %>% 
  summarise()%>% #Merge multipolygons of Flanders, Brussels, and Wallonia into 1 big multipolygon for Belgium
  sf::st_simplify(dTolerance=10) %>% #simpligy the polygon because there were too many points for rgbif
  sf::st_geometry() %>% 
  sf::st_as_text()%>%  
  wk::wkt() %>% 
  wk::wk_orient()#Due to changes in GBIF’s polygon interpretation, you might get an error when using polygons wound in the “wrong direction” (clockwise, i.e., default of sf). Reorient the polygon using the wk package

#Read taxonomic info of alien cube
data_file <- here::here(
  "data",
  "output",
  "UAT_processing",
  "be_alientaxa_info.csv")

cube_info<-read_csv(data_file)

#---------------------------------------------------------------------------------------
# Check for keys that are present in the GRIIS checklist but not be_alientaxa_cube
#---------------------------------------------------------------------------------------

# Extract the nubKey from the griis checklist and the taxonkey from the cube
taxonkeys_griis <- as.integer(GRIIS$nubKey)
taxonkeys_cube<-as.integer(be_alientaxa_cube$taxonKey)

#Get keys from the griss checklist that are not present in the cube
missing_species<- setdiff(taxonkeys_griis, taxonkeys_cube)



#-------------------------------------------------------------------------
# ¨Prepare data for test
#-------------------------------------------------------------------------
  #If all goes well, this should be 0
  all_species_present<-length(missing_species)==0
  
  #in case this is not true, download data of taxonkeys that are not present in alientaxa cube but
  #that do have occurrence data on gbif in Belgium. The same download settings are used as for constructing be_alientaxa_cube
  if(length(missing_species)!=0) {
    
    basis_of_record <- c(
      "OBSERVATION", 
      "HUMAN_OBSERVATION",
      "MATERIAL_SAMPLE", 
      "LITERATURE", 
      "PRESERVED_SPECIMEN", 
      "UNKNOWN", 
      "MACHINE_OBSERVATION")
    
    gbif_download_key <- rgbif::occ_download(
      pred_in("country", "BE"),
      pred_in("taxonKey", missing_species),
      pred("hasCoordinate", TRUE),
      #pred_within(belgium),
      pred_in("basisOfRecord", basis_of_record),
      pred_gte("year", 1000),
      pred_lte("year", year(Sys.Date()))
    )
    
    #Follow the status of the download    
    occ_download_wait(gbif_download_key)
    
    #Retrieve downloaded records
   species_records <- occ_download_get(gbif_download_key,overwrite = TRUE) %>%
      occ_download_import() 
   
   #Only keep relevant columns
   species_records<-species_records %>%
     filter(!grepl("COORDINATE_OUT_OF_RANGE", issue) | 
            !grepl("ZERO_COORDINATE", issue) |
              !grepl("COORDINATE_INVALID", issue) | 
              !grepl("COUNTRY_COORDINATE_MISMATCH", issue)) %>%
     filter(!identificationVerificationStatus%in%c(
       "unverified",
       "unvalidated",
       "not validated",
       "under validation",
       "not able to validate",
       "control could not be conclusive due to insufficient knowledge",
       "uncertain",
       "unconfirmed",
       "unconfirmed - not reviewed",
       "validation requested",
       "Non réalisable"))%>%
   filter(!occurrenceStatus %in% c("ABSENT", "EXCLUDED"))%>%
     select(c("scientificName","taxonKey", "speciesKey","genusKey","familyKey","taxonomicStatus","taxonRank","acceptedTaxonKey" ))
   
  species_records_species<-species_records%>%
     select(-taxonKey)%>%
     filter(taxonRank %in% c("SPECIES", "GENUS", "FAMILY"), 
            taxonomicStatus %in% c("ACCEPTED", "DOUBTFUL"))%>%
     mutate(speciesKey = as.integer(speciesKey),
            genusKey = as.integer(genusKey),
            familyKey = as.integer(familyKey)) %>%
     filter(speciesKey %in% missing_species |
            genusKey %in% missing_species |
            familyKey %in% missing_species)%>%
     filter(!is.na(speciesKey) & speciesKey != 0)%>%
     rename(taxonKey = speciesKey)%>%
    select(-acceptedTaxonKey)
    
   
   species_records_subspecies <- species_records %>%
     select(-c(taxonKey,speciesKey))%>%
     filter(taxonRank %in% c("SUBSPECIFICAGGREGATE",
                        "SUBSPECIES", 
                        "VARIETY",
                        "SUBVARIETY",
                        "FORM",
                        "SUBFORM"), 
            taxonomicStatus %in% c("ACCEPTED", "DOUBTFUL")) %>%
     rename(taxonKey = acceptedTaxonKey)
   
  species_records_subspecies<-species_records_subspecies[,c(1,6,2:5)]
     
    species_records_synonyms <-species_records %>%
     filter(!taxonomicStatus %in% c("ACCEPTED", "DOUBTFUL"))%>%
      select(-c(speciesKey,acceptedTaxonKey))
     
   species_records<-rbind (species_records_species,species_records_subspecies,species_records_synonyms)
   
   
   species_records<-species_records %>%
     group_by(taxonKey,scientificName,taxonRank, taxonomicStatus) %>%
     count()
    

    #Only keep taxonkeys in missing_species that were present in downloaded species_records
    missing_species <- missing_species[missing_species %in% species_records$taxonKey]
    
    #Filter the GRIIS checklist on these missing keys to paste the scientific name of these taxonkeys (as indicated in the GRIIS checklist) in the next step
    missing_details<-GRIIS %>%
      dplyr::filter(nubKey %in% missing_species) %>%
      distinct(nubKey, .keep_all=TRUE)
    

    # Check if each scientificName is present in any row of the includes column of cube info
    missing_details$present_in_includes <- sapply(missing_details$scientificName, function(name) {
      any(grepl(name, cube_info$includes))
    })
      missing_details<-filter(missing_details, present_in_includes==FALSE)
   

  }



#-------------------------------------------------------------------------
# ¨Define test
#-------------------------------------------------------------------------
test_that("All species of the GRIIS checklist are included in be_alientaxa_cube", {
  # Expect that all values are present
  expect_true(all_species_present, info = cat(paste0("There are ",nrow(missing_details)," species on the GRIIS checklist that are not present in be_alientaxa_cube but DO have GBIF occurrence records located in Belgium. They have the following nubKeys: ", paste0(missing_details$nubKey, collapse = ", "),
                                                     '\n',
                                                     '\n',
                                                     "These correspond to the following scientific names: ", paste0(missing_details$scientificName, collapse = ", "))))
})



