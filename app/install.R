#!/usr/bin/env Rscript

withCallingHandlers(
  install.packages(c(
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
    "shinydashboardPlus",
    "shinyBS",
    "shinyjs",
    "shinythemes",
    "shinyWidgets",
    "yaml"
  )),
  warning=stop
)
