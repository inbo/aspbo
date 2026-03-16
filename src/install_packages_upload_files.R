# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c("aws.s3", "magrittr", "readr",
  "dplyr", "tidyr", "stringr",
  "testthat", "remotes"
)
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install)
}

# install custom packages
remotes::install_github("inbo/INBOtheme@v0.5.9", force = TRUE)
remotes::install_github("inbo/alien-species-portal@uat", 
                        subdir = "alienSpecies", force = TRUE)

# Test if minimum version of aws.s3 is installed
if (packageVersion("aws.s3") < "0.3.22") {
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n
      ==> installing v0.3.22 from https://rforge.net")
  remotes::install_version("aws.s3", version = "0.3.22", repos = "https://rforge.net")
}else{
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n")
}
