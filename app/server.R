###### Methylation Shiny app ######

# this is a two file shinly application the other
# one is called ui.R

# Alper Celik


suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(DT))
suppressPackageStartupMessages(library(shinyWidgets))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(shinyBS))
suppressPackageStartupMessages(library(openssl))
suppressPackageStartupMessages(library(RPostgreSQL))
suppressPackageStartupMessages(library(shinydashboardPlus))
suppressPackageStartupMessages(library(shinydashboard))
suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(bsplus))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(shinycssloaders))

options(shiny.maxRequestSize=50*1024^2)


#parameteds is hardcoded do not move config.yaml file
parameters<-yaml.load_file("config.yaml")
modules<-paste0(parameters$basepath, parameters$app_files$appdir, unlist(parameters$app_files$modules))

for(module in modules){
  source(module)
}



server<-function(input, output, session){
  #database connection making it a global variable

  envs<-Sys.getenv()

# connect to db
  #conn<<-dbConnect(drv = PostgreSQL(), envs["POSTGRES_HOST"],
  #            user=as.character(envs["POSTGRES_USER"]),
  #            password=as.character(envs["POSTGRES_PASSWORD"]),
  #            dbname=as.character(envs["POSTGRES_DB"]),
  #            port=as.integer(envs["POSTGRES_HOST_PORT"]))

  conn<<-dbConnect(drv = PostgreSQL(), envs["POSTGRES_HOST"],
              user=as.character(envs["POSTGRES_USER"]),
              password=as.character(envs["POSTGRES_PASSWORD"]),
              dbname=as.character(envs["POSTGRES_DB"]),
              port=as.character(envs["POSTGRES_PORT"]))

  dbSendStatement(conn, "SET search_path = samples_users;")

  #Keeping track of tabs for browser history
  justUpdated <- reactiveVal(FALSE)
  observeEvent(getQueryString()[["tab"]],{
    req(input$tabs)
    newTabRequest <- getQueryString()[["tab"]]
    justUpdated(FALSE)
    if (newTabRequest != input$tabs){
      updateTabItems(session, "tabs", newTabRequest)
      justUpdated(TRUE)
    }
  })

  observeEvent(input$tabs,{
    if (justUpdated()) {
      justUpdated(FALSE)
      return(NULL)
    }
    updateQueryString(paste0("?tab=",input$tabs), mode = "push")
  })

  user_login_info<-reactiveValues(userid=NULL, username=NULL, admin=F, login=F)

  #if everyything is null then return the login screen by defaul
  user_login_info<-callModule(login_server, id="login_screen", parameters=parameters, user=user_login_info)
  #if user_status()$login is true and the user is not admin below will display otherwise will be null
  callModule(user_server, id="user_screen", parameters=parameters, user=user_login_info)
  #if user_status()$login is true and the user is admin below will display otherwise will be null
  #callModule(module = admin_server, id="admin_screen", conn=conn, status=user_status)

  #TODO errorcheck
  session$onSessionEnded(
    function(){
      #access<-data.frame(time=Sys.time(), username=user_login_info$username, action="logout", status="success")
      #dbWriteTable(conn, "access", access, append=T, row.names=F)
      dbDisconnect(conn = conn)
    }
  )
}
