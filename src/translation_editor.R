library(shiny)
library(dplyr)
library(readr)
library(htmltools)

# Function to load data
load_data <- function() {
  translations <- read_csv2("../data/output/UAT_direct/translations.csv")
  return(translations)
}

# Initial data load
translations <- load_data()

# Define UI
ui <- fluidPage(
  titlePanel("Translation Editor"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("title_id", "Select Title ID:", choices = unique(translations$title_id)),
      selectInput("language", "Select Language:", choices = c("en", "fr", "nl")),
      actionButton("save", "Save Changes")
    ),
    
    mainPanel(
      textAreaInput("title_unformatted", "Title (Unformatted):", width = "100%", height = "100px"),
      htmlOutput("title_rendered"),
      textAreaInput("description_unformatted", "Description (Unformatted):", width = "100%", height = "200px"),
      htmlOutput("description_rendered")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Reactive value to store translations
  translations_rv <- reactiveVal(translations)
  
  # Update title_id choices after data is loaded
  observe({
    updateSelectInput(session, "title_id", choices = unique(translations_rv()$title_id))
  })
  
  # Reactive expression to filter data based on selected title_id
  filtered_data <- reactive({
    req(input$title_id)
    translations_rv() %>% filter(title_id == input$title_id)
  })
  
  # Update text inputs when title_id or language changes
  observe({
    req(filtered_data())
    lang_col_title <- paste0("title_", input$language)
    lang_col_description <- paste0("description_", input$language)
    
    updateTextAreaInput(session, "title_unformatted", value = filtered_data()[[lang_col_title]])
    updateTextAreaInput(session, "description_unformatted", value = filtered_data()[[lang_col_description]])
  })
  
  # Render HTML for title and description
  output$title_rendered <- renderUI({
    req(input$title_unformatted)
    HTML(input$title_unformatted)
  })
  
  output$description_rendered <- renderUI({
    req(input$description_unformatted)
    HTML(input$description_unformatted)
  })
  
  # Save changes and reload data
  observeEvent(input$save, {
    req(filtered_data())
    
    # Update the translations data frame with the new values
    lang_col_title <- paste0("title_", input$language)
    lang_col_description <- paste0("description_", input$language)
    
    updated_translations <- translations_rv()
    updated_translations[updated_translations$title_id == input$title_id, lang_col_title] <- input$title_unformatted
    updated_translations[updated_translations$title_id == input$title_id, lang_col_description] <- input$description_unformatted
    
    # Save to CSV
    write_csv2(updated_translations, "../data/output/UAT_direct/translations.csv")
    
    # Reload data
    new_translations <- load_data()
    translations_rv(new_translations)
    
    showModal(modalDialog(
      title = "Success",
      "Changes have been saved successfully and data has been reloaded!",
      easyClose = TRUE,
      footer = NULL
    ))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
