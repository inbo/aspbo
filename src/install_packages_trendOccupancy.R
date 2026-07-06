# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("remotes", "knitr", "dplyr", "magrittr", "readr", "tidyr", 
              "stringr", "testthat", "sf")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}
