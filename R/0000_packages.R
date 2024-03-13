################################################################################
## Date: 07/02/2024
## Overview: Current 
## Author: Chris Mainey, BSOL ICB
## Description: Check for and install R packages required
##
################################################################################

## Packages to install

c_cran_packages <- c("tidyverse","remotes", "DBI", "odbc", "httr", "jsonlite"
                     , 'DT', 'miniUI', 'shiny', 'shinycssloaders' # Dependencies for Fingertips
                     )
c_github_packages <- c("rOpenSci/fingertipsR")


# Functions to check installed packages and install if missing.
add_packages_cran <- function(p){
if (!is.element(p, installed.packages()[,1]))
  install.packages(p
                   , dependencies = TRUE)
}

add_packages_github <- function(p){
  if (!is.element(p, installed.packages()[,1]))
    remotes::install_github(p
                     , build_vignettes = TRUE
                     , dependencies = "suggests")
}

# Run
lapply(c_cran_packages, add_packages_cran)
lapply(c_github_packages, add_packages_github)
