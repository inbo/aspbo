# Libraries
library(magrittr)
library(dplyr)
library(devtools)
# update alienSpecies 
inbotheme_version <- as.data.frame(installed.packages()) %>% 
  filter(Package == "INBOtheme")

if(inbotheme_version$Version != "0.5.8"){
  remove.packages("INBOtheme")
  install_github("inbo/INBOtheme@v0.5.8")
}

install_github("inbo/alien-species-portal@sprint_v0.0.4", 
                         subdir = "alienSpecies", force = TRUE)
