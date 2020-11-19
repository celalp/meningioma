###### Methylation Shiny app ######

# this is a two file shinly application the other
# one is called server.R

# Alper Celik


suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(shinythemes))
suppressPackageStartupMessages(library(DT))
suppressPackageStartupMessages(library(shinyWidgets))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(DBI))
suppressPackageStartupMessages(library(shinyBS))
suppressPackageStartupMessages(library(bsplus))
suppressPackageStartupMessages(library(shinydashboardPlus))
suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(shinycssloaders))

#parameteds is hardcoded do not move config.yaml file
parameters<-yaml.load_file("../config.yaml")
modules<-paste0(parameters$basepath, parameters$app_files$appdir, unlist(parameters$app_files$modules))

for(module in modules){
  source(module)
}

ui<-navbarPage("Methylation App", theme = shinytheme("cosmo"), inverse = F, selected = "home", 
               id = "tabs", collapsible = T, position="fixed-top",
               useShinydashboardPlus(),
               useShinyjs(),
               # home page is a static page, the entire UI will be rendered here
               tabPanel("Home", icon = icon("home"), value = "home", 
                        br(),
                        br(),
 
                        # browser leave page warning
                        ########### ENABLE WHEN DONE ###########
                        #tags$head(tags$script("window.onbeforeunload = function() { return true; }")), 
                        
                        fluidRow(tags$img(src="img/banner.jpg", style="width: 100%;")),
                        
                        fluidRow(
                          column(width=8, offset = 2, 
                                 br(),
                                 tags$h1(strong("Toronto Meningioma Recurrence Score ")),
                                 tags$p(style="font-size: 18px;", "In a multicentre study, Nassiri et al. (2019) demonstrated the transformative utility of 
                                        combining the methylome of a specific patient’s meningioma with established clinical factors 
                                        such as WHO grade and extent of resection in order to predict an individual’s 5-year recurrence 
                                        risk more reliably than with clinical factors alone. This website represents the access point 
                                        whereby clinicians and scientists can utilize the meningioma recurrence nomogram in order to 
                                        determine a patient’s individualized risk of recurrence following tumor resection."),
                                 column(width=7,
                                 tags$h1(strong("Implementation of Methylation Profiling of Meningiomas")),
                                        tags$p(style="font-size: 18px;", "In order to implement the meningioma recurrence nomogram, we ask that you generate and upload 
                                               unprocessed IDAT-files of Illumina 450k HumanMethylation BeadChip or 850k EPIC arrays of your meningioma. 
                                               This data is then incorporated into our established methylome-based predictor to produce a 5-year methylome 
                                               probability based on methylation of the tumor. You will then be asked to input the pertinent clinical factors 
                                               of 1) WHO grade, and 2) Simpson Grade of resection. These will be incorporated into our clinical recurrence 
                                               nomogram along with the tumor methylome probability of recurrence and a predicted recurrence-free survival 
                                               probability will be outputted for the specific time point requested.")
                                 ), 
                                 column(width=5, 
                                        fluidRow(
                                          tags$img(src="img/landing_side.jpg", style="width: 100%;")
                                        ))
                          )
                        ),
                        
                        fluidRow(
                          column(width = 2,  tags$img(src="img/footer_left.jpg", style="height: 100%;")),
                          column(width = 3, offset = 7,  sytle="position:relative;", tags$img(src="img/footer_right.jpg", style="position: absoulute; width: 100%; top:10px;")),
                                 )
                        
               ),
               # this is the only dynamic portion of the page separated into three modules 
               # depending on the login status see server.R for additional comments
               tabPanel("App", icon=icon("chart-bar"), value = "app", 
                        br(),
                        br(),
                        br(),
                        br(),
                        login_ui("login_screen"),
                        user_ui("user_screen")
               )
)

