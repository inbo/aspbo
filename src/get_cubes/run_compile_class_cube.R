# Load script specific libraries
library(knitr)
library(dplyr)
library(magrittr)

# create temporary R file
tempR <- tempfile(fileext = ".R")
knitr::purl("src/get_cubes/compile_class_cube.Rmd", output=tempR)
source(tempR)
unlink(tempR)

