# this is the code that renders and checks sample info and files when the user click upload sample button

upload_sample_ui<-function(id){
  ns<-NS(id)
  tagList(
    fluidRow(
      column(width = 6,
             h3("Sample info"),
             textInput(inputId = ns("upload_samplename"), label = "Sample Name (Required, max 75 characters)", value = ""), 
             radioGroupButtons(inputId = ns("upload_simpson"), label = "Simpson Score", 
                               choices = c("1", "2", "3", "4", "5", "NA"), status = "primary", selected = "NA"),
             radioGroupButtons(inputId = ns("upload_who"), label = "WHO Grade", 
                               choices = c("1", "2", "3", "NA"), status = "primary", selected = "NA"),
             textAreaInput(inputId = ns("upload_sample_info"), label = "Sample Description (Required, max 500 characters)", 
                           resize = "none", value = "")
      ),
      column(width=6,
             h3("Files"),
             fileInput(inputId = ns("green"), label = "Green channel file", multiple = F, accept = ".idat"),
             fileInput(inputId = ns("red"), label = "Red channel file", multiple = F, accept = ".idat"),
             bsAlert("sample_submission_alert"),
             bsAlert("sample_exists_alert")
             
      )),
    br(),
    br(),
    actionButton(inputId = ns("sample_check"), label = "Prepare for submission", icon = icon("wrench")),
    uiOutput(ns("sample_submit"))
  )
}



upload_sample_server<-function(input, output, session, user, parameters){
  # here several checks happen before the sample is even submitted for analysis
  # to make sure that there are enough processes to run the pipeline is single threaded
  # and samples are prepared one by one. This increases the analysis time but makes sure that
  # the shiny interface have enough resource to continue, it also allows for reverse proxy to 
  # load balance when needed 
  
  samples<-reactiveValues(samples=NULL)
  ready<-reactiveVal(F)
  sexists<-reactiveVal(F)
  
  observeEvent(input$sample_check, {
    
    samp_query<-"select * from samples_users.samples where sampleid in 
                (select sampleid from samples_users.samples_users_linked where userid=?id)"
    samp_query<-sqlInterpolate(conn, samp_query, id=user$userid)
    samp<-dbGetQuery(conn, samp_query)
    samples$samples<-samp
    if(nrow(samples$samples)>0){
      if(input$upload_samplename %in% samples$samples$samplename){
        closeAlert(session, "sample_exists_alert_control")
        createAlert(session, "sample_exists_alert", "sample_exists_alert_control", title="", 
                    content="You already have a sample with that name, please choose another one", style = "info")
        sexists(T)
      } else {
        closeAlert(session, "sample_exists_alert_control")
        sexists(F)
      }
      
    } 
    
    if(nchar(input$upload_samplename)==0 | nchar(input$upload_sample_info)==0){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content="Please fill all the required fields", style = "danger")
      ready(F)
    } else if(nchar(input$upload_samplename)>75){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content=paste("Your sample name is too long:", nchar(input$upload_samplename)), style = "danger")
      ready(F)
      #TODO character count
    } else if(nchar(input$upload_sample_info)>500){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content=paste("Your sample description is too long:", nchar(input$upload_sample_info)), style = "danger")
      ready(F)
    } else if (is.null(input$green) | is.null(input$red)){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content="Please upload both green and red idat files", style = "danger")
      ready(F)
    } else if (!grepl("Grn.idat", input$green$name) | !grepl("Red.idat", input$red$name)){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content="Your green and red channel filenames do not have the proper file extensions 
                  ('Grn.idat' and 'Red.idat' respectively) ", 
                  style = "danger")
      ready(F)
    } else if(gsub("_Grn.idat", "", input$green$name)!=gsub("_Red.idat", "", input$red$name)){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content="Your green and red channel filenames are different please double check your uploaded files
                  and re-upload", 
                  style = "danger")
      ready(F)
    } else if (input$upload_who=="NA" | input$upload_simpson=="NA"){
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content="Without simpson and who grades we will not be able to predict recurrence probability. You 
                  can still process your samples by clicking Process Sample button below or you can update the score before
                  submtting samples", 
                  style = "warning")
      ready(T)
    } else {
      closeAlert(session, "sample_submission_alert_control")
      ready(T)
    }
  })
  
  output$sample_submit<-renderUI({
    if(ready() & !sexists()){
      tagList(actionButton(session$ns("process_sample"), "Process Sample", icon=icon("terminal")))
    } else {
      NULL
    }
  })
  
  
  ############ Start Analysis ###########
  observeEvent(input$process_sample, {
    path<-paste0(parameters$basepath, parameters$sample_files, user$username, "/", input$upload_samplename)
    # create folder for the sample files
    # check if the folder alreay is there that means there is a database error major bug
    if(!dir.exists(path)){
      tryCatch({
        sampledir<-paste0(parameters$basepath, parameters$sample_files, user$username, "/", input$upload_samplename)
        dir.create(paste0(parameters$basepath, parameters$sample_files, user$username, "/", input$upload_samplename), 
                   mode = 0600)
        if(file.exists(input$green$datapath)){
          gcopy<-file.copy(input$green$datapath, sampledir)
          file.rename(from = paste0(sampledir, "/0.idat"), to = paste0(sampledir, "/", input$green$name))
        } else {
          closeAlert(session, "sample_submission_alert_control")
          createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title = "", 
                      content = "Green channel file upload error please try again", style = "warning")
        }
        if(file.exists(input$red$datapath)){
          rcopy<-file.copy(input$red$datapath, paste0(parameters$basepath, parameters$sample_files, user$username, "/", input$upload_samplename))
          file.rename(from = paste0(sampledir, "/0.idat"), to = paste0(sampledir, "/", input$red$name))
        } else {
          closeAlert(session, "sample_submission_alert_control")
          createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title = "", 
                      content = "Red channel file upload error please try again", style = "warning")
        }
        if(rcopy & gcopy){
          info<-paste(paste0("'", c(input$upload_samplename, as.character(Sys.time()), input$upload_who, input$upload_simpson, "queued for analysis",
          input$upload_sample_info),"'"), collapse=",")
          newsample<-paste("insert into samples_users.samples (samplename, added, who_grade, simpson_score, status, description) values (",
                           info, ") returning sampleid")
          sampleid<-dbGetQuery(conn, newsample)$sampleid
          linker<-data.frame(userid=user$userid, sampleid=sampleid)
          dbWriteTable(conn, "samples_users_linked", linker, append=T, row.names=F)
          analysis<-data.frame(time=Sys.time(), message="sample uploaded", status="success", 
                               username=user$username, samplename=input$upload_samplename)
          dbWriteTable(conn, "analysis", analysis, append=T, row.names=F)
          closeAlert(session, "sample_submission_alert_control")
          createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title = "", 
                      content = "Your files have been queued for analysis, they will be processed in the order they are recieved, 
                      please come back later for results", 
                      style = "success")
          
          samp_query<-"select * from samples_users.samples where sampleid in 
                (select sampleid from samples_users.samples_users_linked where userid=?id)"
          samp_query<-sqlInterpolate(conn, samp_query, id=user$userid)
          samp<-dbGetQuery(conn, samp_query)
          samples$samples<-samp
          ready(F)
          
        } else {
          closeAlert(session, "sample_submission_alert_control")
          createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title = "", 
                      content = "There was an error while registering your files. Please try again later, if the problem 
                      persists please contact admin", style = "danger")
          ready(F)
        }
      }, warning=function(w){
        closeAlert(session, "sample_submission_alert_control")
        createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title = "", 
                    content = "We are having issues with submitting your sample for analysis please try again later 
                        if the problem persists please contact admin", style = "danger")
        analysis<-data.frame(time=Sys.time(), message="analysis_init", status="fail", 
                             username=user$username, samplename=input$upload_samplename)
        dbWriteTable(conn, "analysis", analysis, append=T, row.names=F)
        ready(F)
      })
    } else {
      closeAlert(session, "sample_submission_alert_control")
      createAlert(session, "sample_submission_alert", "sample_submission_alert_control", title="", 
                  content="Seems like there already is a folder with your samplename but the records are not in our database
                  please contact admin to fix this error", 
                  style = "danger")
      ready(F)
    }
  })
  
}