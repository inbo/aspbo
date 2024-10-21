#-------------------------------------------------------------------------
#Load package testthat, and install it when this has not been done before
#-------------------------------------------------------------------------

packages <- c("testthat","sf","utils","readr","here")

for(package in packages) {
  if( ! package %in% rownames(installed.packages()) ) { install.packages( package ) }
  library(package, character.only = TRUE)
}


#-------------------------------------------------------------------------
#List the datasets to test
#-------------------------------------------------------------------------
#Specify folders holding the datasets to test
folders<-c("./data/output/UAT_processing/Vespa_velutina_shape",
           "./data/output/UAT_direct")

#List files in those folders
datasets <- unlist(lapply(folders, function(folder) {
  list.files(folder, pattern = "\\.(geojson|csv)$", full.names = TRUE)
}))

#Remove certain files that don't need to be checked
datasets<-datasets[!datasets %in% c("./data/output/UAT_direct/translations_simple.csv",
                                    "./data/output/UAT_direct/translations_regions.csv",
                                    "./data/output/UAT_direct/translations.csv",
                                    "./data/output/UAT_direct/harmonia_info.csv",
                                    "./data/output/UAT_processing/Vespa_velutina_shape/aantal_nesten_meta.csv")
]


#-------------------------------------------------------------------------
#Extract region translations
#-------------------------------------------------------------------------
translations_regions<-read.csv2(here("data", "output", "UAT_direct", "translations_regions.csv"))

# Extract the reference column from translations_regions 
region_values <- translations_regions$title_id


#-------------------------------------------------------------------------
# Define the tests
#-------------------------------------------------------------------------


test_that("Region names and columns are indicated correctly in files", { 
  
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

