#-------------------------------------------------------------------------
#Load package testthat, and install it when this has not been done before
#-------------------------------------------------------------------------

packages <- c("testthat","sf","utils","readr")

for(i in packages) {
  if( ! i %in% rownames(installed.packages()) ) { install.packages( i ) }
  library(i, character.only = TRUE)
}


#-------------------------------------------------------------------------
#Load the data of the datasets that you want to test
#-------------------------------------------------------------------------
points <- st_read("./data/output/UAT_processing/Vespa_velutina_shape/points.geojson")
nesten<- st_read("./data/output/UAT_processing/Vespa_velutina_shape/nesten.geojson")
aantal_gemelde_nesten<- st_read("./data/output/UAT_processing/Vespa_velutina_shape/aantal_gemelde_nesten.geojson")
aantal_lente_nesten<- read.csv("./data/output/UAT_processing/Vespa_velutina_shape/aantal_lente_nesten.csv")
actieve_haarden<- st_read("./data/output/UAT_processing/Vespa_velutina_shape/actieve_haarden.geojson")
beheerde_nesten<- st_read("./data/output/UAT_processing/Vespa_velutina_shape/beheerde_nesten.geojson")
onbehandelde_nesten<- st_read("./data/output/UAT_processing/Vespa_velutina_shape/onbehandelde_nesten.geojson")


#-------------------------------------------------------------------------
#Load the translations file
#-------------------------------------------------------------------------
#translations_regions<-read.csv2("./data/output/UAT_direct/translations_regions.csv")
translations_regions<-read_csv2("https://raw.githubusercontent.com/inbo/aspbo/121-update-translations-file/data/output/UAT_direct/translations_regions.csv")


#-------------------------------------------------------------------------
# create list of datasets
#-------------------------------------------------------------------------
datasets <- list(nesten=nesten, points=points, aantal_gemelde_nesten=aantal_gemelde_nesten,aantal_lente_nesten=aantal_lente_nesten,
                 actieve_haarden=actieve_haarden,beheerde_nesten=beheerde_nesten,onbehandelde_nesten=onbehandelde_nesten)


#-------------------------------------------------------------------------
# Define the test
#-------------------------------------------------------------------------

test_that("Region IDs in Vespa output files correspond to those in translations_regions file", {
  
  # Extract the reference column from translations_regions 
  region_values <- translations_regions$title_id
  
  for(datasetname in names(datasets)){
    filetype <- switch(datasetname,
                       "nesten" = ".geojson",
                       "points" = ".geojson",
                       "aantal_gemelde_nesten" = ".geojson",
                       "actieve_haarden" = ".geojson",
                       "beheerde_nesten" = ".geojson",
                       "onbehandelde_nesten" = ".geojson",
                       "aantal_lente_nesten" = ".csv",
                       "")
    
    filename<-datasets[[datasetname]]
    
    for (level in c("level1Name","level2Name","level3Name","NAAM","GEWEST","provincie","Gemeente","prov")){
      
      if (level %in% colnames(filename)) {
        regions_to_check<-filename[[level]]
        
        #Get translations that may not be present in translations_regions
        wrong_translations<- setdiff(regions_to_check, region_values)
        
        translation_IDs_okay<-length(wrong_translations)==0
        
        # Expect that all values are present
        expect_true(translation_IDs_okay, info = paste0("The following values in column ", level, " in the file ", datasetname,filetype, " are not present in translations_regions:", paste(wrong_translations, collapse = ", ")))
      }
    }
  }
})

