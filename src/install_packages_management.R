# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c("rgbif", "sf", "geojsonsf",
              "dplyr", "tidyr", "stringr",
              "uuid", "readr"
)
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install)
}
