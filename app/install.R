#!/usr/bin/env Rscript

withCallingHandlers(
  install.packages(c(
    "devtools",
    "bsplus",
    "DBI",
    "DT",
    "openssl",
    "reshape2",
    "rmarkdown",
    "RPostgreSQL",
    "shiny",
    "shinycssloaders",
    "shinydashboard",
    "shinyBS",
    "shinyjs",
    "shinythemes",
    "shinyWidgets",
    "yaml"
  )),
  warning=stop
)

withCallingHandlers(
  devtools::install_version("shinydashboardPlus", version="0.7.5"),
  warning=stop
)

