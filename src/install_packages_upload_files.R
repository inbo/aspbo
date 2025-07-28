# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c(
  "aws.s3", "magrittr", "readr",
  "dplyr", "tidyr", "stringr",
  "testthat"
)
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install)
}

# Test if minimum version of aws.s3 is installed
if (packageVersion("aws.s3") < "0.3.22") {
  stop("Please update aws.s3 to version 0.3.21 or higher.")
}else{
  cat("aws.s3 version:", paste(unlist(packageVersion("aws.s3")), collapse = "."), "\n")
}
