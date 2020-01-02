# this is the code that renders what's inside the modal when user clicks account settings


account_settings_ui<-function(id, user){
  ns<-NS(id)
  userinfo<-"select * from samples_users.users where userid=?id"
  userinfo<-sqlInterpolate(conn, userinfo, id=isolate(user$userid))
  userinfo<-dbGetQuery(conn, userinfo)
  samples<-"select count(*) from samples_users.samples where sampleid in (select userid from samples_users.users where userid=?id)"
  samples<-sqlInterpolate(conn, samples, id=isolate(user$userid))
  samples<-dbGetQuery(conn, samples)$count
  fluidRow(
    #uiOutput(ns("sample_card")),
    tagList(
      infoBox(
        value=userinfo$username,
        title = paste(userinfo$name, userinfo$middlename, userinfo$lastname),
        subtitle = paste("Account Created on", userinfo$created),
        color = "aqua", icon = icon("user"), width = 12, fill = F),
      column(width = 4, offset = 1,
             renderText(paste(samples, "samples uploaded so far")),
             renderText(paste("Email:", userinfo$email)),
             br(), 
             pickerInput(
               inputId = ns("action"),
               label = "What would you like to do?", 
               choices = c("Update email", "Password change", "Update secret")),
             options = list(
               title = "Change account info"),
             bsAlert("settings_change_alert")
      )),
  column(width = 6, 
         uiOutput(ns("email_change_ui")),
         uiOutput(ns("pw_change_ui")),
         uiOutput(ns("secret_change_ui"))
  )
  )
}

account_settings_server<-function(input, output, session, user, parameters){
  
  enc<-get(parameters$encryption$algorithm)
  
  ################
  # based on what the value of the action selectize is the below ui's will be displayed
  # it might be prudent to move update/reset functions to utils but it would also be difficult to vectorize
  # the same checks as login are perfomed here, the code is similar and that's not ideal
  
  output$email_change_ui<-renderUI({
    if(input$action=="Update email"){ 
      fluidRow(
        wellPanel(
          h4("Update Email"),
          textInput(inputId=session$ns("new_email"), label="New Email Adress"),
          actionButton(inputId=session$ns("update_email"), label="Update Email", icon=icon("user-edit")),
          br()
        ),
        hr()
      )
    } else {
      NULL
    }
  })
  
  output$pw_change_ui<-renderUI({
    if(input$action=="Password change"){ #
      fluidRow(
        wellPanel(
          h4("Update Password"),
          passwordInput(inputId=session$ns("new_password"), label="New Password (min 12 characters)", value = ""),
          passwordInput(inputId=session$ns("confirm_new_password"), label="Confirm New Password", value = ""),
          actionButton(inputId=session$ns("update_pw"), label="Update Password", icon=icon("user-edit")),
          br()
        ),
        hr()
      )
    } else {
      NULL
    }
  })
  
  output$secret_change_ui<-renderUI({
    if(input$action=="Update secret"){ #toggle
      fluidRow(
        wellPanel(
          h4("Update Secret"),
          textInput(inputId=session$ns("new_secret"), label="New Secret (min 10 characters)", value = ""),
          actionButton(inputId=session$ns("update_secret"), label="Update Secret", icon=icon("user-edit")),
          br()
        ),
        hr()
      )
    } else {
      NULL
    }
  })
  
  
  observeEvent(input$update_email, {
    current_email<-"select email from samples_users.users where username=?username"
    current_email<-sqlInterpolate(conn, current_email, username=user$username)
    current_email<-unlist(dbGetQuery(conn, current_email))
    if(nchar(input$new_email)==0 | !grepl("^([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)$", input$new_email)){
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Please enter a valid email address to update", style = "warning")
    } else if (input$new_email==current_email){
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Please enter a different email than your current one", style = "warning")
    } else {
      email_update<-"update samples_users.users set email=?email where username=?username"
      email_update<-sqlInterpolate(conn, email_update, email=input$new_email, username=user$username)
      tryCatch({
        dbSendStatement(conn, email_update)
        closeAlert(session, "settings_change_alert_control")
        createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                    content="Your email has been updated, you will see the changes next time you log in", 
                    style = "success")
        access<-data.frame(time=Sys.time(), username=user$username, action="email_update", status="success")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      }, error=function(e){
        closeAlert(session, "settings_change_alert_control")
        createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                    content="We could not update your email please try again later, if the problem persits please email admin", 
                    style = "danger")
        access<-data.frame(time=Sys.time(), username=user$username, action="email_update", status="fail")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      })
    }
  })
  
  observeEvent(input$update_pw, {
    current_password<-"select password from samples_users.users where username=?username"
    current_password<-sqlInterpolate(conn, current_password, username=user$username)
    current_password<-unlist(dbGetQuery(conn, current_password))
    if(nchar(input$new_password)<12){
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Your password needs to be at least 12 chraracters", style = "warning")
    }else if(input$new_password!=input$confirm_new_password){
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Passwords do not match", style = "warning")
    } else if (enc(input$new_password)==current_password) {
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Please enter a different password than your current one", style = "warning")
    } else{
      password<-toString(enc(input$new_password))
      password_update<-"update samples_users.users set password=?password where username=?username"
      password_update<-sqlInterpolate(conn, password_update, password=password, username=user$username)
      tryCatch({
        dbSendStatement(conn, password_update)
        closeAlert(session, "settings_change_alert_control")
        createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                    content="Your password has been updated, you can use your updated password next time you log in"
                    , style = "success")
        access<-data.frame(time=Sys.time(), username=user$username, action="password_update", status="success")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      }, error=function(e){
        closeAlert(session, "settings_change_alert_control")
        createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                    content="We could not update your password please try again later, if the problem persits please email admin", 
                    style = "danger")
        access<-data.frame(time=Sys.time(), username=user$username, action="password_update", status="fail")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      })
    }
  })
  
  observeEvent(input$update_secret, {
    current_secret<-"select secret from samples_users.users where username=?username"
    current_secret<-sqlInterpolate(conn, current_secret, username=user$username)
    current_secret<-unlist(dbGetQuery(conn, current_secret))
    
    if(nchar(input$new_secret)<10){
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Your secret needs to be at least 10 chraracters", style = "warning")
    } else if (enc(input$new_secret)==current_secret) {
      closeAlert(session, "settings_change_alert_control")
      createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                  content="Please enter a different secret than your current one", style = "warning")
    } else{
      secret<-toString(enc(input$new_secret))
      secret_update<-"update samples_users.users set secret=?secret where username=?username"
      secret_update<-sqlInterpolate(conn, secret_update, secret=secret, username=user$username)
      tryCatch({
        dbSendStatement(conn, secret_update)
        closeAlert(session, "settings_change_alert_control")
        createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                    content="Your secret has been updated", style = "success")
        access<-data.frame(time=Sys.time(), username=user$username, action="secret_update", status="success")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      }, error=function(e){
        closeAlert(session, "settings_change_alert_control")
        createAlert(session, "settings_change_alert", "settings_change_alert_control", title="", 
                    content="We could not update your secret please try again later, if the problem persits please email admin", 
                    style = "danger")
        access<-data.frame(time=Sys.time(), username=user$username, action="secret_update", status="fail")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      })
    }
  })
}