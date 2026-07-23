#' R code to automatically run all chunks of update_oxyura_jamaicensis_management.Rmd

# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("knitr")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}
library(knitr)

# create temporary R file
tempR <- tempfile(fileext = ".R")
knitr::purl("./src/Oxyura jamaicensis management/update_oxyura_jamaicensis_management.Rmd", output=tempR)
source(tempR)
unlink(tempR)
