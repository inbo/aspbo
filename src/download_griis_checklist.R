library(knitr)
library(magrittr)

# run step 1 of Trias workflow ####
tempR <- tempfile(fileext = ".R")
knitr::purl("https://raw.githubusercontent.com/trias-project/indicators/main/src/01_get_data_input_checklist_indicators.Rmd", output=tempR)
source(tempR)
unlink(tempR)

# The structure as presented by Trias is slightly different from the structure 
# of this repository. Therefore, we need to move the file to the correct location.
# move file from Trias to UAT_processing ####
file.copy(from = "./data/interim/data_input_checklist_indicators.tsv",
          to = "./data/output/UAT_processing/data_input_checklist_indicators.tsv",
          overwrite = TRUE)

file.remove("./data/interim/data_input_checklist_indicators.tsv")

print("download successful >> initiating processing")

# run GRIIS_processing script ####
tempR <- tempfile(fileext = ".R")
knitr::purl("./src/GRIIS_processing.Rmd", output=tempR)
source(tempR)
unlink(tempR)

print("processing successful")

