#-------------------------------------------------------------------------
#Load package testthat, and install it when this has not been done before
#-------------------------------------------------------------------------

packages <- c("testthat","utils","readr", "dplyr")

for(i in packages) {
  if( ! i %in% rownames(installed.packages()) ) { install.packages( i ) }
  library(i, character.only = TRUE)
}


#-------------------------------------------------------------------------
#Load the be_alientaxa_cube and GRIIS checklist
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

GRIIS <-GRIIS %>%
  filter(locationId == "ISO_3166:BE")


#-------------------------------------------------------------------------
# Check for missing keys
#-------------------------------------------------------------------------

# Extract the nubKey from the griis checklist and the taxonkey from the cube
taxonkeys_griis <- as.integer(GRIIS$nubKey)
taxonkeys_cube<-as.integer(be_alientaxa_cube$taxonKey)

#Get keys from the griss checklist that are not present in the cube
missing_species<- setdiff(taxonkeys_griis, taxonkeys_cube)


#-------------------------------------------------------------------------
# Define the test
#-------------------------------------------------------------------------

test_that("All species of the GRIIS checklist are included in be_alientaxa_cube", {
  
  #If all goes well, this should be 0
  all_species_present<-length(missing_species)==0
  
  #in case this is not true, extract taxonkeys that are not present
  
  if(length(missing_species)!=0) {
    
    missing_details<-GRIIS %>%
      dplyr::filter(nubKey %in% missing_species)

  }
  
  # Expect that all values are present
  expect_true(all_species_present, info = cat(paste0("There are ",length(missing_species)," species on the GRIIS checklist that are not present in be_alientaxa_cube. They have the following nubKeys: ", paste0(missing_species, collapse = ", "),
                                                     '\n',
                                                     '\n',
                                                     "These correspond to the following scientific names: ", paste0(missing_details$scientificName, collapse = ", "))))
})

rgbif::name_usage(5250090)$data$scientificName
