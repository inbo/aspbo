# get packages installed on machine
installed <- rownames(installed.packages())
# specify packages we need
required <- c("rgbif", "rmarkdown")
# install packages if needed
if (!all(required %in% installed)) {
  pkgs_to_install <- required[!required %in% installed]
  print(paste("Packages to install:", paste(pkgs_to_install, collapse = ", ")))
  install.packages(pkgs_to_install, repos = "https://cran.r-project.org/")
}

# The current flow works with rgbif version 3.8.5.13
if(packageVersion("rgbif") != package_version("3.8.5.13")){
  install.packages("pak")
  pak::pkg_install("ropensci/rgbif@b2e67b758b6dbe4f1df8f62666b49b2c3419897b")
}
  