# this module will handle the bulk of the work where users see their samples and download reports. 
# users will only see the samples that they have uploaded. 
# account settings and sample submission code is under upload_sample.R and account_settings.R

user_ui<-function(id){
  ns<-NS(id)
  uiOutput(ns("user_page"))
}



user_server<-function(input, output, session, parameters, user){
  
  samples<-reactiveValues(samples=NULL)
  
  output$user_page<-renderUI({
    if (!user$login | user$admin) {
      NULL
    } else {
      samp_query<-"select * from samples_users.samples where sampleid in 
                (select sampleid from samples_users.samples_users_linked where userid=?id)"
      samp_query<-sqlInterpolate(conn, samp_query, id=isolate(user$userid))
      samp<-dbGetQuery(conn, samp_query)
      samples$samples<-samp
      tagList(
        br(), 
        column(width =1, offset = 11,
               actionLink(inputId = session$ns("account_settings"), label = "Account Settings", icon = icon("gears")),
               br()
        ),
        br(),
        fluidRow(
          ######## Samples Box ###########
          boxPlus(title = "Samples", status = "primary", collapsible = F, closable = F, width = 4, 
                  output$samples_table<-renderUI({
                    if(length(samples$samples)==0){
                      infoBox(title = "No Samples Found",value = 0, 
                              subtitle="To add samples use the Upload Sample button below", 
                              icon = icon("flask"), color = "teal", width = 12, fill = F)
                    } else {
                      output$samples_dt<-renderDT({
                        datatable(samples$samples[, c("samplename", "added", "status")],
                                  style = "bootstrap", class="compact", rownames = F,
                                  extensions = 'Scroller',
                                  options = list(
                                    deferRender = TRUE,  scrollY = 450, scroller = TRUE, 
                                    lengthChange = F,  dom=c("ft")), 
                                  selection="single")})
                      DTOutput(session$ns("samples_dt"))
                    }  
                  }),
                  br(),
                  actionGroupButtons(inputIds = c(session$ns("upload_sample_button"), session$ns("refresh_table")), 
                                     labels = list(tags$span(icon("upload"), "Upload Sample"), 
                                                   tags$span(icon("refresh"), "Refresh Table")), 
                                     status = "primary")
          ),
          
          ######### Reports Box ###########
          boxPlus(title = "Results", status = "info", collapsible = F, closable = F, width = 8,
                  output$reports<-renderUI({
                    tabsetPanel(
                      tabPanel(title = "Analysis", icon = icon("file"), 
                               if(length(samples$samples)==0){
                                 NULL
                               } else if (length(samples$samples) > 0  & is.null(input$samples_dt_rows_selected)){
                                 tagList(
                                   br(), 
                                   br(),
                                   infoBox(title = "Select sample to view report", value = "", 
                                           subtitle="Click on one of the samples witih status 'Done' to view report", 
                                           icon = icon("search"), color = "navy", width = 12, fill = F)
                                 )
                               } else if (!is.null(input$samples_dt_rows_selected)){
                                 report_path<-paste0(parameters$basepath, parameters$sample_files, user$username, "/", 
                                                     samples$samples[input$samples_dt_rows_selected, "samplename"], 
                                                     "/results/")
                                 if(samples$samples[input$samples_dt_rows_selected, "status"]=="Done"){
                                   selected_sample<-samples$samples[input$samples_dt_rows_selected,]
                                   for_dt<-selected_sample[, c("sampleid", "samplename", "added", "who_grade", "simpson_score", "description")]
                                   colnames(for_dt)<-c("Sample id", "Sample Name", "Date added", "Who grade", "Simpson grade", 
                                                       "Sample description")
                                   output$selected_sample<-renderDT({
                                     datatable(for_dt, style = "bootstrap", class="compact", 
                                               rownames = F, options = list( deferRender = TRUE, extensions = c('Responsive'), 
                                                                             dom=c("t"), ordering=F), selection="none")
                                   })
                                   
                                   tagList(
                                     tags$h3("Sample info"),
                                     DTOutput(session$ns("selected_sample")),
                                     br(),
                                     tags$h4("Detection p value:"),
                                     tags$p(renderText(selected_sample$detection_p)),
                                     tags$p(renderText("This is the average probability of proper signature detection. 
                                          A value > 0.05 indicates poor sample quality")),
                                     tags$h4("5-year methylome probability:"),
                                     tags$p(renderText(selected_sample$methylome_prob)),
                                     tags$p(renderText("This is the probability of 5-year recurrence using a methylome signature derived from the tumour")),
                                     tags$h4("5-year Meningioma Recurrence Score:"),
                                     tags$p(renderText(selected_sample$recurrence_prob)),
                                     tags$p(renderText("This is the probability of 5-year recurrence-free survival calculated using a nomogram that 
                                          incorporated the 5-year methylome probability with established clinical prognostic factors 
                                          (WHO grade and Simpson grade) if provided by the user")),
                                     fluidRow(
                                       column(width = 8,
                                              renderImage({list(src=paste0(report_path, "CNV.png"))}, deleteFile = F)
                                       ),
                                       column(width=4, 
                                              renderImage({list(src=paste0(report_path, "density_plot.png"), width = "100%")}, deleteFile = F)
                                       )),
                                     tags$p("Copy number variation plot generated by methylation raw data. 
                                 Gains/amplifications represent positive, losses negative deviations from the baseline. 
                                 Meningioma relevant gene regions are highlighted for easier assessment. 
                                 (see Hovestadt & Zapatka, http://www.bioconductor.org/packages/devel/bioc/html/conumee.html)"),
                                     #TODO downloads go here
                                     tags$h3("Downloads:"),
                                     br(), 
                                     downloadLink(session$ns("report_down"), "Download pdf report"),
                                     hr(),
                                     downloadLink(session$ns("bins_down"), "Download CNV bins"),
                                     br(),
                                     downloadLink(session$ns("details_down"), "Download CNV details"),
                                     br(),
                                     downloadLink(session$ns("segments_down"), "Download CNV segments"),
                                     hr(), 
                                     br() 
                                   )
                                   
                                 } else if (samples$samples[input$samples_dt_rows_selected, "status"]=="Error! see analysis logs") {
                                   br()
                                   infoBox(title = "Report could not be generated" , value = "", 
                                           subtitle="See analysis logs tab to see the potential cause for error", 
                                           icon = icon("bug"), color = "maroon", width = 12, fill = F)
                                   
                                 } else {
                                   br()
                                   infoBox(title = "Report not yet available", value = "", 
                                           subtitle="Click on one of the samples witih status 'Done' to view report", 
                                           icon = icon("hourglass-half"), color = "olive", width = 12, fill = F)
                                 }
                               }
                      ), 
                      tabPanel(title = "Analysis Logs", icon=icon("tasks"), 
                               if(is.null(samples$samples)){
                                 NULL
                               } else if (length(samples$samples) > 0  & is.null(input$samples_dt_rows_selected)){
                                 tagList(
                                   br(), 
                                   br(),
                                   infoBox(title = "Select sample to view logs", value = "", 
                                           subtitle="Click on one of the samples to view analysis logs", 
                                           icon = icon("list"), color = "light-blue", width = 12, fill = F)
                                 )
                               } else if (!is.null(input$samples_dt_rows_selected)){
                                 output$log_table<-renderDT({
                                   id<-samples$samples[input$samples_dt_rows_selected, "sampleid"]
                                   logs<-"select * from samples_users.analysis where sampleid=?id"
                                   logs<-sqlInterpolate(conn, logs, id=id)
                                   logdf<-dbGetQuery(conn, logs)
                                   logdf<-logdf[order(logdf$id),]
                                   datatable(logdf[,-1], class="compact", rownames = F, 
                                             extensions = 'Scroller',
                                             options = list( deferRender = TRUE,
                                                             scrollY = 450, scroller = TRUE,
                                                             dom=c("t"), ordering=F), selection="none")
                                 })
                                 tagList(
                                   tags$h3("Analysis Logs"),
                                   br(),
                                   DTOutput(session$ns("log_table")),
                                   br(),
                                   br()
                                 )
                               }
                      )
                    )
                  }),
                  
                  output$delete_ui<-renderUI({
                    if(nrow(samples$samples)==0){
                      NULL
                    } else if (nrow(samples$samples) > 0  & is.null(input$samples_dt_rows_selected)) {
                      NULL
                    } else {
                      actionGroupButtons(inputIds = c(session$ns("delete")), 
                                         labels = list(tags$span(icon("trash"), "Delete Sample")), 
                                         status = "danger")
                    }
                  })
          )
        ),
        
        
        ########## Modals ###############
        bsModal("account_settings_modal", "Account Settings", session$ns("account_settings"), size="large", 
                account_settings_ui(session$ns("account_settings_module"), user = user)
        ),
        bsModal("upload_sample_modal", "Upload New Sample", session$ns("upload_sample_button"), size="large", 
                upload_sample_ui(session$ns("upload_sample_module"))  
        )
      )
    }
  })
  
  observeEvent(c(input$refresh_table,input$delete_confirm), {
    samp_query<-"select * from samples_users.samples where sampleid in 
                (select sampleid from samples_users.samples_users_linked where userid=?id)"
    samp_query<-sqlInterpolate(conn, samp_query, id=user$userid)
    samp<-dbGetQuery(conn, samp_query)
    samples$samples<-samp
  })
  
  output$report_down<-downloadHandler(
    filename <- function() {"report.pdf"},
    content <- function(file){
      file.copy(
        paste0(parameters$basepath, parameters$sample_files, user$username, "/", 
               samples$samples[input$samples_dt_rows_selected, "samplename"], 
               "/results/report.pdf"), file)
    }
  )
  
  output$bins_down<-downloadHandler(
    filename <- function() {"CNVbins.igv"},
    content <- function(file) {
      file.copy(paste0(parameters$basepath, parameters$sample_files, user$username, "/", 
                       samples$samples[input$samples_dt_rows_selected, "samplename"], 
                       "/results/CNVbins.igv"), file)
    }
  )
  
  output$details_down<-downloadHandler(
    filename <- function() {"CNVdetail.txt"},
    content <- function(file) {
      file.copy(paste0(parameters$basepath, parameters$sample_files, user$username, "/", 
                       samples$samples[input$samples_dt_rows_selected, "samplename"], 
                       "/results/CNVdetail.txt"), file)
    }
  )
  
  output$segments_down<-downloadHandler(
    filename <- function() {"CNVsegments.seg"},
    content <- function(file) {
      file.copy(paste0(parameters$basepath, parameters$sample_files, user$username, "/", 
                       samples$samples[input$samples_dt_rows_selected, "samplename"], 
                       "/results/CNVsegments.seg"), file)
    }
  )
  
  observeEvent(input$delete, {
    confirmSweetAlert(session = session, inputId = session$ns("delete_confirm"), type = "danger", 
                      title="Confirm Delete",
                      text = "Are you sure want to delete this sample? This cannot be undone!", 
                      btn_labels = c("Cancel", "Delete"), 
                      btn_colors = c("#808080", "#CC0000"), 
                      closeOnClickOutside = TRUE,
                      showCloseButton = T)
  })
  
  observeEvent(input$delete_confirm, {
    if(input$delete_confirm){
      id<-samples$samples[input$samples_dt_rows_selected, "sampleid"]
      name<-samples$samples[input$samples_dt_rows_selected, "samplename"]
      print(name)
      tryCatch({
        withProgress(message = paste("Removing sample", name), {
          incProgress(amount = 1/7, detail = "gathering information")
          
          del_query_samp<-"delete from samples_users.samples where sampleid=?id"
          del_query_samp<-sqlInterpolate(conn, del_query_samp, id=id)
          dbSendStatement(conn, del_query_samp)
          incProgress(amount = 1/7, detail = "deleted from database 1/3")
          
          del_query_link<-"delete from samples_users.samples_users_linked where sampleid=?id"
          del_query_link<-sqlInterpolate(conn, del_query_link, id=id)
          dbSendStatement(conn, del_query_link)
          incProgress(amount = 1/7, detail = "deteled from database 2/3")
          
          del_query_analysis<-"delete from samples_users.analysis where sampleid=?id"
          del_query_analysis<-sqlInterpolate(conn, del_query_analysis, id=id)
          dbSendStatement(conn, del_query_analysis)
          incProgress(amount = 1/7, detail = "deteled from database 3/3")
          
          unlink(paste0(parameters$basepath, parameters$sample_files, user$username,"/", name), recursive = T)
          incProgress(amount = 1/7, detail = "deleted sample files and results")
          
          unlink(paste0(parameters$basepath, parameters$analysis$logs, id, ".log"))
          incProgress(amount = 1/7, detail = "deleted log files")
          
          incProgress(amount = 1/7, detail = "Done")
          showNotification(ui = paste(name, "remmoved from the system it may take up to", 
                                      parameters$backup$frequency, "days for the data to be completeley removed from 
                                 all backups"), type="default", session=session)
        })
      }, error=function(e){
        showNotification(ui = "There was an error removing the sample from our system. Please contact admin to remove the sample manually", 
                         duration=NULL, type="error")
        
      })
      
      
      
      
    } else {
      NULL
    }
  })
  
  callModule(account_settings_server, id = "account_settings_module", user=user, parameters=parameters)
  callModule(upload_sample_server, "upload_sample_module",  user=user, parameters=parameters)
  
  
}