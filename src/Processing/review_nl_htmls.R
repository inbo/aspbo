library(shiny)

# Folder containing the '_nl.html' files
html_folder <- "~/github/aspbo/HTML_pages/HTML/"

cat(path.expand(html_folder), dir(html_folder))

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
  
  # Load list of html filenames ending with _nl.html
  all_files <- list.files(html_folder, pattern = "_nl\\.html$", full.names = FALSE)
  
  # Extract base names before _nl
  base_names <- sub("_nl\\.html$", "", all_files)
  
  # ReactiveValues for tracking indices and lists
  rv <- reactiveValues(
    current_idx = 1,
    ok_list = character(),
    de_list = character(),
    het_list = character(),
    redo_all = NULL,
    files_to_review = NULL
  )
  
  # Startup modal dialog to ask redo all or only unchecked
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
  
  observeEvent(input$modal_dismiss, {
    # No button clicked or modal dismissed
    if (is.null(rv$redo_all)) {
      rv$redo_all <- FALSE
      # Determine unchecked files (not in any list)
      checked <- unique(c(rv$ok_list, rv$de_list, rv$het_list))
      unchecked_files <- all_files[!base_names %in% checked]
      rv$files_to_review <- if (length(unchecked_files) == 0) all_files else unchecked_files
      rv$current_idx <- 1
      removeModal()
    }
  }, once = TRUE)
  
  # Because modalButton doesn't trigger input explicitly, simulate modal dismiss event
  observe({
    if (!is.null(rv$redo_all)) return()
    invalidateLater(1000, session)
    if (is.null(session$clientData)) return()
    if (!isTruthy(input$redo_yes) && !isTruthy(input$btn_ok) && !isTruthy(input$btn_de) && !isTruthy(input$btn_het) && !isTruthy(input$btn_skip)) {
      # Assume dismissed if no interaction
      session$sendCustomMessage(type = "dismissModal", message = list())
    }
  })
  
  # Helper to get current HTML file path
  current_file <- reactive({
    if (is.null(rv$files_to_review)) return(NULL)
    if (rv$current_idx > length(rv$files_to_review)) return(NULL)
    file.path(html_folder, rv$files_to_review[rv$current_idx])
  })
  
  # Display current HTML content
  output$html_content <- renderUI({
    file <- current_file()
    if (is.null(file)) return(h4("No more HTML files to review."))
    includeHTML(file)
  })
  
  # Button handler for storing and moving to next file
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
  
  # Download handlers for each list as text file
  output$download_ok <- downloadHandler(
    filename = function() {
      paste0("ok_list_", Sys.Date(), ".txt")
    },
    content = function(file) {
      writeLines(rv$ok_list, file)
    }
  )
  output$download_de <- downloadHandler(
    filename = function() {
      paste0("de_list_", Sys.Date(), ".txt")
    },
    content = function(file) {
      writeLines(rv$de_list, file)
    }
  )
  output$download_het <- downloadHandler(
    filename = function() {
      paste0("het_list_", Sys.Date(), ".txt")
    },
    content = function(file) {
      writeLines(rv$het_list, file)
    }
  )
}

shinyApp(ui, server)
