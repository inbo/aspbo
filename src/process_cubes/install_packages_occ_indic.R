# install CRAN packages ####
# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("remotes", "knitr", "dplyr", "magrittr", "rgbif", "tidylog", 
              "progress", "here", "lubridate", "readr", "purrr",
              "stringr", "tidyr", "aws.s3", "sf", "testthat", "pbapply", 
              "aws.ec2metadata")

if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed], dependencies = TRUE)
}

# Test if minimum version of aws.s3 is installed
if (packageVersion("aws.s3") < "0.3.22") {
  install.packages("devtools")
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n
      ==> installing v0.3.22 from https://rforge.net")
  remotes::install_version("aws.s3", version = "0.3.22", repos = "https://rforge.net")
}else{
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n")
}

# ensure dependencies are installed ####
if(!requireNamespace("aws.ec2metadata", quietly = TRUE)){
  warning("1st 'aws.ec2metadata' installation failed, retrying")
  install.packages("aws.ec2metadata", 
                   dependencies = TRUE)
}

# install non-CRAN packages ####
remotes::install_github("trafficonese/leaflet.extras", force = TRUE)
remotes::install_github("inbo/INBOtheme@v0.5.9", force = TRUE)
remotes::install_github("inbo/alien-species-portal@fix_v1.3.0", 
                         subdir = "alienSpecies", force = TRUE)