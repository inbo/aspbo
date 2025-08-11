# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c("rgbif", "sf", "googlesheets4", "dplyr", "tidyr", "devtools", "readr",
"ggplot2", "testthat"
)
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install, repos = "https://cran.r-project.org/")
}

# install fistools
devtools::install_github("inbo/fistools")