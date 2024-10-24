# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("devtools", "knitr", "dplyr", "magrittr", "rgbif", "tidylog", 
              "progress", "here", "lubridate", "readr", "purrr",
              "stringr", "tidyr", "aws.s3", "sf", "testthat")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}
