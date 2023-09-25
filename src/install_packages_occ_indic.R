# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("devtools", "knitr", "dplyr", "magrittr", "rgbif", "tidylog", 
              "progress", "here", "lubridate", "readr", "purrr",
              "stringr", "tidyr")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}

install_github("inbo/INBOtheme@v0.5.8")