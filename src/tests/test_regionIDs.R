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
folders<-c("./data/output/UAT_processing",
           "./data/output/UAT_direct",
           "./data/output/UAT_direct/Vespa_velutina_shape")

#List files in those folders
datasets <- unlist(lapply(folders, function(folder) {
  list.files(folder, pattern = "\\.(geojson|csv)$", full.names = TRUE)
}))

#Remove certain files that don't need to be checked
datasets<-datasets[!datasets %in% c("./data/output/UAT_direct/translations_simple.csv",
                                    "./data/output/UAT_direct/translations_regions.csv",
                                    "./data/output/UAT_direct/translations.csv",
                                    "./data/output/UAT_direct/harmonia_info.csv",
                                    "./data/output/UAT_processing/Vespa_velutina_shape/aantal_nesten_meta.csv",
                                    "./data/output/UAT_processing/be_alientaxa_cube.csv",
                                    "./data/output/UAT_processing/be_alientaxa_info.csv",
                                    "./data/output/UAT_processing/communes.geojson",
                                    "./data/output/UAT_processing/provinces.geojson")
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
  
  for(i in seq_along(datasets)){
    
    #Select dataset
    filename<-datasets[[i]]
    
    #Get datasetname
    datasetname <- sub(".*/([^/]+)\\.[^.]+$", "\\1", filename)
    
    #Get Extension
    extension <- sub(".*\\.", "", filename)
    
    #Read in the data
    if(extension=="geojson"){
      #Read in data
      filename<-st_read(filename, quiet=TRUE)
    }
    
    if(extension=="csv"){
      #Read in data
      filename<- suppressMessages(read.csv(filename))
    }
    
    
    #----------------Check that 'gemeente', 'provincie', and 'gewest', are present in colnames-------------
    # Extract column names from the dataset
    column_names <- colnames(filename)
    
    # Check if all values are present in the column names
    all_columns_present<- all(c("gemeente", "provincie", "gewest") %in% column_names)
    
    #If not values are present, check which ones are missing
    missing_columns<- setdiff( c("gemeente", "provincie", "gewest"), column_names)
    
    # Run test for column names
    expect_true(all_columns_present, info = paste0("The following columns are not present in the file ", datasetname,".",extension, ": ", paste(missing_columns, collapse = ", ")))                      
 
    for (level in c("gemeente","provincie","gewest")){
      if (level %in% column_names) {
        regions_to_check<-filename[[level]]
        
        #Get translations that may not be present in translations_regions
        wrong_translations<- setdiff(regions_to_check, region_values)
        
        translation_IDs_okay<-length(wrong_translations)==0
        
        
        # Expect that all values are present
        expect_true(translation_IDs_okay, info = paste0("The following values in column ", level, " in the file ", datasetname,".",extension, " are not present in translations_regions: ", paste(wrong_translations, collapse = ", ")))
        
      }
    }
  }
})




    