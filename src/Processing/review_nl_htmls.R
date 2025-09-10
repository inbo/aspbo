library(shiny)

html_folder <- "~/github/aspbo/HTML_pages/HTML/"

# Define paths for previous lists
ok_list_path <- "./data/interim/links_html_ok_list.txt"
de_list_path <- "./data/interim/links_html_de_list.txt"
het_list_path <- "./data/interim/links_html_het_list.txt"

ui <- fluidPage(
  titlePanel("HTML Review App"),
  uiOutput("html_content"),
  br(),
  actionButton("btn_ok", "ok"),
  actionButton("btn_de", "de"),
  actionButton("btn_het", "het"),
  actionButton("btn_skip", "skip"),
  br(),
  br(),
  downloadButton("download_ok", "Download OK List"),
  downloadButton("download_de", "Download DE List"),
  downloadButton("download_het", "Download HET List")
)

server <- function(input, output, session) {
  # Load all HTML files w/ '_nl.html' ending
  all_files <- list.files(html_folder, pattern = "_nl\\.html$", full.names = FALSE)
  base_names <- sub("_nl\\.html$", "", all_files)
  
  # Helper to read list safely (returns character vector or empty if not present)
  safe_read <- function(path) {
    if (file.exists(path)) readLines(path) else character(0)
  }
  
  # Initial loading of already checked lists
  ok_initial <- safe_read(ok_list_path)
  de_initial <- safe_read(de_list_path)
  het_initial <- safe_read(het_list_path)
  
  rv <- reactiveValues(
    current_idx = 1,
    ok_list = ok_initial,
    de_list = de_initial,
    het_list = het_initial,
    redo_all = NULL,
    files_to_review = NULL
  )
  
  # Startup modal
  showModal(modalDialog(
    title = "Redo checked HTMLs?",
    "Do you want to redo all files (Yes) or only files not yet checked (No)?",
    footer = tagList(
      modalButton("No"),
      actionButton("redo_yes", "Yes")
    )
  ))
  
  # Handle "Yes": redo all files
  observeEvent(input$redo_yes, {
    rv$redo_all <- TRUE
    rv$files_to_review <- all_files
    rv$current_idx <- 1
    removeModal()
  })
  
  # Handle "No" or modal dismissed
  observe({
    if (!is.null(rv$redo_all)) return()
    if (!is.null(input$redo_yes)) return()
    # Check for modal dismiss (simulate with a delay since modalButton doesn't trigger an input)
    invalidateLater(250, session)
    if (isTruthy(input$btn_ok) || isTruthy(input$btn_de) || isTruthy(input$btn_het) || isTruthy(input$btn_skip)) return()
    # If still undecided after a small delay, treat as "No"
    isolate({
      checked <- unique(c(ok_initial, de_initial, het_initial))
      unchecked_files <- all_files[!base_names %in% checked]
      rv$redo_all <- FALSE
      rv$files_to_review <- if (length(unchecked_files) == 0) all_files else unchecked_files
      rv$current_idx <- 1
      removeModal()
    })
  })
  
  current_file <- reactive({
    if (is.null(rv$files_to_review)) return(NULL)
    if (rv$current_idx > length(rv$files_to_review)) return(NULL)
    file.path(html_folder, rv$files_to_review[rv$current_idx])
  })
  
  output$html_content <- renderUI({
    file <- current_file()
    if (is.null(file)) return(h4("No more HTML files to review."))
    includeHTML(file)
  })
  
  observeEvent(input$btn_ok, {
    if (!is.null(current_file())) {
      val <- sub("_nl\\.html$", "", basename(current_file()))
      rv$ok_list <- unique(c(rv$ok_list, val))
      rv$current_idx <- rv$current_idx + 1
    }
  })
  observeEvent(input$btn_de, {
    if (!is.null(current_file())) {
      val <- sub("_nl\\.html$", "", basename(current_file()))
      rv$de_list <- unique(c(rv$de_list, val))
      rv$current_idx <- rv$current_idx + 1
    }
  })
  observeEvent(input$btn_het, {
    if (!is.null(current_file())) {
      val <- sub("_nl\\.html$", "", basename(current_file()))
      rv$het_list <- unique(c(rv$het_list, val))
      rv$current_idx <- rv$current_idx + 1
    }
  })
  observeEvent(input$btn_skip, {
    if (!is.null(current_file())) {
      rv$current_idx <- rv$current_idx + 1
    }
  })
  
  output$download_ok <- downloadHandler(
    filename = function() ok_list_path,
    content = function(file) writeLines(rv$ok_list, file)
  )
  output$download_de <- downloadHandler(
    filename = function() de_list_path,
    content = function(file) writeLines(rv$de_list, file)
  )
  output$download_het <- downloadHandler(
    filename = function() het_list_path,
    content = function(file) writeLines(rv$het_list, file)
  )
}

shinyApp(ui, server)
