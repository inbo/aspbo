library(shiny)
library(shinyjs)  # for dynamic CSS class toggle

html_folder <- "~/github/aspbo/HTML_pages/HTML/"
ok_list_path <- "~/github/aspbo/data/interim/links_html_ok_list.txt"
de_list_path <- "~/github/aspbo/data/interim/links_html_de_list.txt"
het_list_path <- "~/github/aspbo/data/interim/links_html_het_list.txt"

ui <- fluidPage(
  useShinyjs(),  # initialize shinyjs for the app
  tags$style(HTML("
    .highlighted {
      background-color: lightgreen !important;
      color: black !important;
    }
  ")),
  titlePanel("HTML Review App"),
  fluidRow(
    column(6,
           textInput("search_name", "Search HTML by base name", placeholder = "Enter base name without '_nl.html' ...")),
    column(2,
           actionButton("btn_search", "Load HTML"))
  ),
  uiOutput("html_content"),
  br(),
  actionButton("btn_ok", "ok"),
  actionButton("btn_de", "de"),
  actionButton("btn_het", "het"),
  actionButton("btn_skip", "skip"),
  br(),
  br(),
  actionButton("btn_save", "Save Lists")
)

server <- function(input, output, session) {
  safe_read <- function(path) {
    if (file.exists(path)) readLines(path) else character(0)
  }
  
  all_files <- list.files(html_folder, pattern = "_nl\\.html$", full.names = FALSE)
  base_names <- sub("_nl\\.html$", "", all_files)
  
  ok_initial <- safe_read(ok_list_path)
  de_initial <- safe_read(de_list_path)
  het_initial <- safe_read(het_list_path)
  
  combined_list <- data.frame(
    name = c(ok_initial, de_initial, het_initial),
    article = c(
      rep("ok", length(ok_initial)),
      rep("de", length(de_initial)),
      rep("het", length(het_initial))
    ),
    stringsAsFactors = FALSE
  )
  combined_list <- combined_list[!duplicated(combined_list$name, fromLast = TRUE), ]
  
  rv <- reactiveValues(
    current_idx = 1,
    combined_df = combined_list,
    redo_all = NULL,
    files_to_review = NULL,
    search_file = NULL
  )
  
  showModal(modalDialog(
    title = "Redo checked HTMLs?",
    "Do you want to redo all files (Yes) or only files not yet checked (No)?",
    footer = tagList(
      modalButton("No"),
      actionButton("redo_yes", "Yes")
    )
  ))
  
  observeEvent(input$redo_yes, {
    rv$redo_all <- TRUE
    rv$files_to_review <- all_files
    rv$current_idx <- 1
    removeModal()
  })
  
  observe({
    if (!is.null(rv$redo_all)) return()
    if (!is.null(input$redo_yes)) return()
    invalidateLater(250, session)
    if (isTruthy(input$btn_ok) || isTruthy(input$btn_de) || isTruthy(input$btn_het) || isTruthy(input$btn_skip)) return()
    isolate({
      checked <- unique(rv$combined_df$name)
      unchecked_files <- all_files[!base_names %in% checked]
      rv$redo_all <- FALSE
      rv$files_to_review <- if (length(unchecked_files) == 0) all_files else unchecked_files
      rv$current_idx <- 1
      removeModal()
    })
  })
  
  current_file <- reactive({
    if (!is.null(rv$search_file)) {
      searched <- paste0(rv$search_file, "_nl.html")
      file_path <- file.path(html_folder, searched)
      if (file.exists(file_path)) return(file_path)
      else return(NULL)
    } else {
      if (is.null(rv$files_to_review)) return(NULL)
      if (rv$current_idx > length(rv$files_to_review)) return(NULL)
      file.path(html_folder, rv$files_to_review[rv$current_idx])
    }
  })
  
  output$html_content <- renderUI({
    file <- current_file()
    if (is.null(file)) return(h4("No HTML file to display or no more HTML files to review."))
    includeHTML(file)
  })
  
  current_base <- reactive({
    if (!is.null(rv$search_file)) {
      rv$search_file
    } else if (!is.null(rv$files_to_review) && rv$current_idx <= length(rv$files_to_review)) {
      sub("_nl\\.html$", "", rv$files_to_review[rv$current_idx])
    } else {
      NULL
    }
  })
  
  # Highlight the chosen article button dynamically with shinyjs
  observe({
    base <- current_base()
    if (is.null(base)) return()
    df <- rv$combined_df
    article <- df$article[df$name == base]
    # Remove highlight class from all buttons first
    shinyjs::removeClass("btn_ok", "highlighted")
    shinyjs::removeClass("btn_de", "highlighted")
    shinyjs::removeClass("btn_het", "highlighted")
    if (length(article) == 1) {
      if(article == "ok") shinyjs::addClass("btn_ok", "highlighted")
      if(article == "de") shinyjs::addClass("btn_de", "highlighted")
      if(article == "het") shinyjs::addClass("btn_het", "highlighted")
    }
  })
  
  update_article <- function(base, new_article) {
    isolate({
      df <- rv$combined_df
      if (base %in% df$name) {
        df$article[df$name == base] <- new_article
      } else {
        df <- rbind(df, data.frame(name = base, article = new_article, stringsAsFactors = FALSE))
      }
      rv$combined_df <- df
    })
  }
  
  observeEvent(input$btn_ok, {
    base <- current_base()
    req(base)
    if (!is.null(rv$search_file)) {
      update_article(base, "ok")
    } else {
      update_article(base, "ok")
      rv$current_idx <- rv$current_idx + 1
    }
  })
  observeEvent(input$btn_de, {
    base <- current_base()
    req(base)
    if (!is.null(rv$search_file)) {
      update_article(base, "de")
    } else {
      update_article(base, "de")
      rv$current_idx <- rv$current_idx + 1
    }
  })
  observeEvent(input$btn_het, {
    base <- current_base()
    req(base)
    if (!is.null(rv$search_file)) {
      update_article(base, "het")
    } else {
      update_article(base, "het")
      rv$current_idx <- rv$current_idx + 1
    }
  })
  
  observeEvent(input$btn_skip, {
    if (is.null(rv$search_file)) {
      if (!is.null(current_file())) rv$current_idx <- rv$current_idx + 1
    } else {
      rv$search_file <- NULL
    }
  })
  
  observeEvent(input$btn_search, {
    req(input$search_name)
    search_val <- trimws(input$search_name)
    if (search_val == "") {
      showNotification("Please enter a base name to search.", type = "error")
      return()
    }
    if (search_val %in% base_names) {
      rv$search_file <- search_val
    } else {
      showNotification(paste0("File for '", search_val, "' not found."), type = "error")
    }
  })
  
  observeEvent(input$btn_save, {
    df <- rv$combined_df
    writeLines(df$name[df$article == "ok"], ok_list_path)
    writeLines(df$name[df$article == "de"], de_list_path)
    writeLines(df$name[df$article == "het"], het_list_path)
    showNotification("Lists saved to disk.", type = "message")
  })
}

shinyApp(ui, server)
