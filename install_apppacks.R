

install.packages("BiocManager", repos="https://cloud.r-project.org")

BiocManager::install(c("shiny", "DT", "shinyWidgets", "DBI", "reshape2", "shinyBS", 
	"openssl", "RPostgreSQL", "shinydashboardPlus", "shinydashboard", "yaml", 
	"bsplus", "shinyjs", "shinycssloaders", "shinythemes"))

