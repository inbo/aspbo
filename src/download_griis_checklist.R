library(knitr)

# create temporary R file ####
tempR <- tempfile(fileext = ".R")
knitr::purl("https://raw.githubusercontent.com/trias-project/indicators/main/src/01_get_data_input_checklist_indicators.Rmd", output=tempR)
source(tempR)
unlink(tempR)

# move file to UAT_processing ####
file.copy(from = "./data/interim/data_input_checklist_indicators.tsv",
          to = "./data/output/UAT_processing/data_input_checklist_indicators.tsv",
          overwrite = TRUE)

file.remove("./data/interim/data_input_checklist_indicators.tsv")