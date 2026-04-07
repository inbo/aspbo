# install CRAN packages ####
# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c("aws.s3", "magrittr", "readr",
              "dplyr", "rgbif", "remotes"
)
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install)
}

# install non-CRAN packages ####
remotes::install_github("trafficonese/leaflet.extras", force = TRUE)
remotes::install_github("inbo/INBOtheme@v0.5.9", force = TRUE)
remotes::install_github("inbo/alien-species-portal@uat", 
                         subdir = "alienSpecies", force = TRUE)