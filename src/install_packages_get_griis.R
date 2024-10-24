# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c("tidyverse", "rgbif", "tidylog", "janitor", "here", "devtools"
)
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install, repos = "https://cran.r-project.org/")
}

# install trias
devtools::install_github("trias-project/trias")
