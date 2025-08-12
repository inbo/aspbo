# load required packages (install them if needed)
installed <- rownames(installed.packages())
required <- c("devtools", "knitr", "dplyr", "magrittr", "readr", "tidyr", 
              "stringr", "testthat", "sf")
if (!all(required %in% installed)) {
  install.packages(required[!required %in% installed])
}

# Test if minimum version of aws.s3 is installed
if (packageVersion("aws.s3") < "0.3.22") {
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n
      ==> installing v0.3.22 from https://rforge.net")
  devtools::install_version("aws.s3", version = "0.3.22", repos = "https://rforge.net")
}else{
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n")
}