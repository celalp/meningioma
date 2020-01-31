# this module handes login/logout and signup and password reset


login_ui<-function(id){
  ns<-NS(id)
  tagList(
    uiOutput(ns("login_page"))
  )
}

login_server<-function(input, output, session, parameters, user){
  
  enc<-get(parameters$encryption$algorithm)
  
  output$login_page<-renderUI({
    if(user$login){
      column(width = 1, offset = 11,
             tagList(
               renderText(paste("Hello,", user$username)),
               actionLink(session$ns("logout_link"), label = paste("Logout"), icon=icon("sign-out-alt")),
               br()
             ))
    } else {
      column(width=4, offset = 4,
             wellPanel(
               tabsetPanel(id=session$ns("login_tabs"),
                           tabPanel(title = "Login", value = "login_screen", icon = icon("sign-in-alt"), 
                                    br(),
                                    br(),
                                    textInput(inputId = session$ns("login_username"), "Username", value = ""),
                                    passwordInput(inputId = session$ns("login_password"), "Password", value = ""),
                                    # this is a modal
                                    actionLink(inputId = session$ns("forgot_password"), "Forgot password"),
                                    bsModal("forgot_password_show", "Reset password", session$ns("forgot_password"), size="small", 
                                            textInput(inputId = session$ns("forgot_username"), "Username  (required)", value=""),
                                            textInput(inputId = session$ns("forgot_email"), "Email  (required)", value=""),
                                            textInput(inputId = session$ns("forgot_secret"), "Secret  (required)", value=""),
                                            passwordInput(inputId = session$ns("forgot_password1"), "New Password  (required min 12 characters)", value = ""), 
                                            passwordInput(inputId = session$ns("forgot_password2"), "Verify Password  (required)", value=""),
                                            bsAlert("forgot_password_alert"),
                                            actionButton(inputId = session$ns("reset_password_button"), label = "Reset Password", 
                                                         style="default")
                                    ),
                                    br(),
                                    br(),
                                    bsAlert("login_alert"),
                                    br(),
                                    actionButton(inputId =  session$ns("login_button"), "Log in", style="primary")), 
                           tabPanel(title = "Signup", value="signup", icon = icon("user-plus"), 
                                    br(),
                                    br(),
                                    textInput(inputId = session$ns("signup_username"), "Username", value = ""),
                                    textInput(inputId = session$ns("name"), "Name (required)", value = ""),
                                    textInput(inputId = session$ns("middlename"), "Middle Name", value = ""),
                                    textInput(inputId = session$ns("lastname"), "Last Name (required)", value = ""),
                                    textInput(inputId = session$ns("signup_email"), "Email (required)", value = ""),
                                    passwordInput(inputId = session$ns("signup_password1"), "Password (required min 12 characters)", value = ""), 
                                    passwordInput(inputId = session$ns("signup_password2"), "Verify Password (required)", value = ""),
                                    textInput(inputId = session$ns("signup_secret"), "Secret (required min 10 characters)", 
                                              value="") %>%
                                      shinyInput_label_embed(
                                        shiny_iconlink() %>%
                                          bs_embed_popover(
                                            title = "For verfication if you want to reset your password", content = "", 
                                            placement = "left"
                                          )),
                                    checkboxInput(inputId = session$ns("agree"), "I have read and accept the"),
                                    actionLink(inputId =  session$ns("terms_modal"), "Terms and Conditions"),
                                    br(),
                                    br(),
                                    bsAlert("signup_alert"),
                                    bsModal("terms_modal_show", "Terms and Conditions", session$ns("terms_modal"), size="large", 
                                            tagList(includeMarkdown(paste0(parameters$basepath, parameters$app_files$appdir, 
                                                                           "www/static/terms_and_conditions.md")))
                                    ),
                                    br(),
                                    br(),
                                    actionButton(inputId = session$ns("signup_button"), label = "Sign up", style="primary")
                           )
               )
             )
      )
    }
  })
  
  
  #####################################
  ##### Login and Activation ##########
  #####################################
  
  usernames<-unlist(dbGetQuery(conn, "select username from samples_users.users"))
  
  observeEvent(input$login_button, {
    if(nchar(input$login_username)==0 | nchar(input$login_password)==0){
      closeAlert(session, "login_alert_control")
      createAlert(session, "login_alert", "login_alert_control", title = "", 
                  content = "Please provide your username and password", style = "info")
    } else {
      passwd<-toString(sha512(input$login_password))
      user_sql<-"select userid,username,name,admin,active from samples_users.users where username = ?username and password = ?password"
      user_query<-sqlInterpolate(conn, user_sql, username=input$login_username, password=passwd)
      user_info<-dbGetQuery(conn, user_query)
      if(nrow(user_info)==0){
        access<-data.frame(time=Sys.time(), username=input$login_username, action="login", status="fail/wrong info")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
        closeAlert(session, "login_alert_control")
        createAlert(session, "login_alert", "login_alert_control", title = "", 
                    content = "Incorrect username and/or password", style = "danger")
      } else if (nrow(user_info)==1){ # we got a hit this user is logging in
        closeAlert(session, "login_alert_control")
        if(!user_info$active & !dir.exists(paste0(parameters$basepath, parameters$sample_files, user_info$username))){ 
          #first time log in so need to creat a home directory
          tryCatch({
            dir.create(paste0(parameters$basepath, parameters$sample_files, user_info$username), mode=0600)
            activate<-"update samples_users.users set active='t' where username=?username"
            activate<-sqlInterpolate(conn, activate, username=user_info$username)
            dbSendStatement(conn, activate)
            access<-data.frame(time=Sys.time(), username=input$login_username, action="activate", status="success")
            dbWriteTable(conn, "access", access, append=T, row.names=F)
          }, error=function(e){
            closeAlert(session, "login_alert_control")
            createAlert(session, "login_alert", "login_alert_control", title = "", 
                        content = "We are having issues creating your home folder please try again later 
                        if the problem persists please contact admin", style = "warning")
            access<-data.frame(time=Sys.time(), username=input$login_username, action="activate", status="fail")
            dbWriteTable(conn, "access", access, append=T, row.names=F)
          })
        }
        links<-"select sampleid from samples_users.samples_users_linked where userid=?userid"
        links_sql<-sqlInterpolate(conn, links, userid=user_info$userid)
        sampleids<-dbGetQuery(conn, links_sql)
        access<-data.frame(time=Sys.time(), username=input$login_username, action="login", status="success")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
        user$userid<-user_info$userid
        user$username<-user_info$username
        user$admin<-user_info$admin
        user$login<-T
      } else {
        closeAlert(session, "login_alert_control")
        createAlert(session, "login_alert", "login_alert_control", title = "", 
                    content = "There is an error with your account please contact admin", style = "danger")
        access<-data.frame(time=Sys.time(), username=input$login_username, action="login", status="fail/system")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      }
    }
  })
  
  
  #####################################
  ########## password reset  ##########
  #####################################
  
  observeEvent(input$reset_password_button, {
    if(nchar(input$forgot_username)==0 | nchar(input$forgot_email)==0 | 
       nchar(input$forgot_password1)==0 |  nchar(input$forgot_password2)==0 | nchar(input$forgot_secret)==0){
      closeAlert(session, "forgot_password_alert_control")
      createAlert(session, "forgot_password_alert", "forgot_password_alert_control", title="", 
                  content="You must fill all required fields", style = "warning")
    } else  if(nchar(input$forgot_password1)<12){
      closeAlert(session, "forgot_password_alert_control")
      createAlert(session, "forgot_password_alert","forgot_password_alert_control", title="", 
                  content="Your password needs to be at least 12 chraracters", style = "warning")
    } else if(input$forgot_password1!=input$forgot_password2){
      closeAlert(session, "forgot_password_alert_control")
      createAlert(session, "forgot_password_alert", "forgot_password_alert_control", title="", 
                  content="Passwords to not match", style = "warning")
    } else {
      secret<-toString(enc(input$forgot_secret))
      search<-"select username,email,password,secret from samples_users.users where username=?username and email=?email and secret=?secret"
      search<-sqlInterpolate(conn, search, username=input$forgot_username, email=input$forgot_email, secret=secret)
      search<-dbGetQuery(conn, search)
      if(nrow(search)==0){
        closeAlert(session, "forgot_password_alert_control")
        createAlert(session, "forgot_password_alert", "forgot_password_alert_control", title="", 
                    content="We did not find any matching records please check your entries", style = "warning")
        access<-data.frame(time=Sys.time(), username=input$forgot_username, action="password_reset", status="no_match")
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      } else if (nrow(search)==1) {
        password<-toString(enc(input$forgot_password1))
        if(password==search$password){
          closeAlert(session, "forgot_password_alert_control")
          createAlert(session, "forgot_password_alert", "forgot_password_alert_control", title="", 
                      content="Your new password cannot be the same as the old one", style = "warning")
          access<-data.frame(time=Sys.time(), username=input$forgot_username, action="password_reset", status="same_pass")
          dbWriteTable(conn, "access", access, append=T, row.names=F)
        } else {
          reset<-"update samples_users.users set password=?password where username=?username"
          reset<-sqlInterpolate(conn, reset, password=password, username=input$forgot_username)
          tryCatch({
            dbSendStatement(conn, reset)
            closeAlert(session, "forgot_password_alert_control")
            createAlert(session, "forgot_password_alert", "forgot_password_alert_control", title="", 
                        content="Your password has been reset you can login using your new password", style = "success")
            access<-data.frame(time=Sys.time(), username=input$forgot_username, action="password_reset", status="success")
            dbWriteTable(conn, "access", access, append=T, row.names=F)
          }, error=function(e) {
            closeAlert(session, "forgot_password_alert_control")
            createAlert(session, "forgot_password_alert", "forgot_password_alert_control", title="", 
                        content="We currently cannot access your records please try again later
                      if the problem persists please contact admin", style = "danger")
            access<-data.frame(time=Sys.time(), username=input$forgot_username, action="password_reset", status="fail")
            dbWriteTable(conn, "access", access, append=T, row.names=F)
          })
        }
      }
    } 
  })
  
  #####################################
  ######## Account Creation ###########
  #####################################
  observeEvent(input$signup_button, {
    usernames<-unlist(dbGetQuery(conn, "select username from samples_users.users"))
    if(nchar(input$signup_username)==0 | nchar(input$name)==0 | 
       nchar(input$lastname)==0 | nchar(input$signup_email)==0 | nchar(input$signup_password1)==0 | 
       nchar(input$signup_password2)==0 | nchar(input$signup_secret)==0){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="You must fill all required fields", style = "warning")
    } else if (!grepl("^([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)$", 
                       input$signup_email)){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="Please enter a valid email address to update", style = "warning")
    } else if (input$signup_username %in% usernames){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="That username is already taken", style = "warning")
    } else if (input$signup_password1 != input$signup_password2){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="Passwords do not match", 
                  style = "warning")
    } else if (input$signup_password1==input$signup_secret){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="Your secreet cannot be the same as your password", 
                  style = "warning")
    } else  if(nchar(input$signup_password1)<12){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert","signup_alert_control", title="", 
                  content="Your password needs to be at least 12 chraracters", style = "warning")
    } else if (nchar(input$signup_secret)<10){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="Your secreet is too short, needs to be at least 10 characters", 
                  style = "warning")
    } else if (!input$agree){
      closeAlert(session, "signup_alert_control")
      createAlert(session, "signup_alert", "signup_alert_control", title="", 
                  content="You must agree to terms and conditions to use this platform", 
                  style = "warning")
    } else {
      password<-toString(enc(input$signup_password1))
      secret<-toString(enc(input$signup_secret))
      signup_df<-data.frame(username=input$signup_username, 
                            name=input$name, middlename=input$middlename, 
                            lastname=input$lastname, created=Sys.time(), 
                            password=password, secret=secret,
                            admin=F, active=F, email=input$signup_email)
      tryCatch({
        dbWriteTable(conn, "users", signup_df, append=T, row.names=F)
        status<-"success"
        closeAlert(session, "signup_alert_control")
        createAlert(session, "signup_alert", "signup_alert_control", title="", 
                    content="Your account has been created please use the sign in tab to activate and log in.", 
                    style = "success")
      }, error=function(e){
        status<-"fail"
        closeAlert(session, "signup_alert_control")
        createAlert(session, "signup_alert", "signup_alert_control", title="", 
                    content="There was an error in creating your account please check the signup form for 
                    any errors if the problem persists you can contact admin", style = "danger")
      }, finally= {
        access<-data.frame(time=Sys.time(), username=input$signup_username, action="signup", status=status)
        dbWriteTable(conn, "access", access, append=T, row.names=F)
      })
    }
  })
  
  #TODO errorcheck
  observeEvent(input$logout_link, {
    access<-data.frame(time=Sys.time(), username=user$username, action="logout", status="success")
    dbWriteTable(conn, "access", access, append=T, row.names=F)
    user$userid<-NULL
    user$username=NULL
    user$admin=F
    user$login=F
  })
  
  return(user)
}








