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


#parameteds is hardcoded do not move config.yaml file
parameters<-yaml.load_file("../config.yaml")
modules<-paste0(parameters$basepath, parameters$app_files$appdir, unlist(parameters$app_files$utils$modules))

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
                        br(),
                        br(),
                        # browser leave page warning
                        ########### ENABLE WHEN DONE ###########
                        #tags$head(tags$script("window.onbeforeunload = function() { return true; }")), 
                        #TODO have an html to source
                        tags$img(src="img/micro2.jpg", style="width:100%;"), 
                        fluidRow(
                          column(width=8, offset = 2, 
                                 br(),
                                 tags$h1("Header1"),
                                 tags$p(" Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent volutpat i
                        mperdiet urna, tincidunt mollis orci varius ut. Nulla facilisi. Nullam luctus eros id
                        magna placerat sagittis. Quisque eget quam hendrerit, viverra purus nec, vulputate sem.
                        Maecenas placerat, nibh sit amet blandit tempus, ante magna iaculis mauris, vitae convallis 
                        mauris dolor et felis. Vestibulum ut risus risus. Duis placerat, erat sit amet dapibus maximus, 
                        odio quam euismod lectus, eu facilisis metus ipsum nec leo. Nam neque nisl, pharetra et ullamcorper sit 
                        amet, sagittis eu nisl. Maecenas scelerisque risus nisi, ac congue metus vehicula in. Aliquam feugiat at 
                        nulla sed tempor. Maecenas nunc odio, luctus a dolor vitae, consequat iaculis neque. Integer id nunc facilisis, 
                        fringilla mauris id, consectetur enim."),
                                 tags$h1("Header2"),
                                 column(width=8,
                                        tags$p(" Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent volutpat i
                        mperdiet urna, tincidunt mollis orci varius ut. Nulla facilisi. Nullam luctus eros id
                        magna placerat sagittis. Quisque eget quam hendrerit, viverra purus nec, vulputate sem.
                        Maecenas placerat, nibh sit amet blandit tempus, ante magna iaculis mauris, vitae convallis 
                        mauris dolor et felis. Vestibulum ut risus risus. Duis placerat, erat sit amet dapibus maximus, 
                        odio quam euismod lectus, eu facilisis metus ipsum nec leo. Nam neque nisl, pharetra et ullamcorper sit 
                        amet, sagittis eu nisl. Maecenas scelerisque risus nisi, ac congue metus vehicula in. Aliquam feugiat at 
                        nulla sed tempor. Maecenas nunc odio, luctus a dolor vitae, consequat iaculis neque. Integer id nunc facilisis, 
                        fringilla mauris id, consectetur enim.")
                                 ), 
                                 column(width=4, 
                                        fluidRow(
                                          tags$img(src="img/louis-reed-747388-unsplash.jpg", style="height: 100%;
                                 width: 100%;")
                                        ))
                          )
                        )
                        
                        
                        
                        
               ),
               # this is the only dynamic portion of the page separated into three modules 
               # depending on the login status see server.R for additional comments
               # TODO add first time admin account creation
               tabPanel("App", icon=icon("chart-bar"), value = "app", 
                        br(),
                        br(),
                        br(),
                        br(),
                        login_ui("login_screen"),
                        user_ui("user_screen")#,
                        #admin_ui("admin_screen")
               )
)
