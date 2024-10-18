# Load script specific libraries
library(knitr)
library(dplyr)
library(magrittr)

# create temporary R file
tempR <- tempfile(fileext = ".R")
knitr::purl("src/get_cubes/build_queries.Rmd", output=tempR)
source(tempR)
unlink(tempR)

