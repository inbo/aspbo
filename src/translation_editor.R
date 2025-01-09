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
  
  # Reactive value to store translations data
  translations_rv <- reactiveVal(translations)
  
  # Reactive values to store the current selections of title_id and language
  current_title_id <- reactiveVal(NULL)
  current_language <- reactiveVal(NULL)
  
  # Update the dropdown choices for Title ID whenever data is reloaded
  observe({
    updateSelectInput(session, "title_id", 
                      choices = unique(translations_rv()$title_id),
                      selected = current_title_id()) # Retain current selection
  })
  
  # Update the dropdown choices for Language and retain the current selection
  observe({
    updateSelectInput(session, "language", 
                      choices = c("en", "fr", "nl"),
                      selected = current_language()) # Retain current selection
  })
  
  # Update reactive values when user selects a Title ID or Language
  observeEvent(input$title_id, {
    current_title_id(input$title_id) # Store selected Title ID
  })
  
  observeEvent(input$language, {
    current_language(input$language) # Store selected Language
  })
  
  # Reactive expression to filter translations data based on selected Title ID
  filtered_data <- reactive({
    req(input$title_id) # Ensure Title ID is selected before proceeding
    translations_rv() %>% filter(title_id == input$title_id)
  })
  
  # Update text areas when Title ID or Language changes
  observe({
    req(filtered_data()) # Ensure filtered data is available
    
    lang_col_title <- paste0("title_", input$language)       # Column name for title in selected language
    lang_col_description <- paste0("description_", input$language) # Column name for description in selected language
    
    updateTextAreaInput(session, "title_unformatted", value = filtered_data()[[lang_col_title]])
    updateTextAreaInput(session, "description_unformatted", value = filtered_data()[[lang_col_description]])
  })
  
  # Render HTML content for the title in real-time as user types in the text area
  output$title_rendered <- renderUI({
    req(input$title_unformatted) # Ensure input is not NULL before rendering HTML
    HTML(input$title_unformatted)
  })
  
  # Render HTML content for the description in real-time as user types in the text area
  output$description_rendered <- renderUI({
    req(input$description_unformatted) # Ensure input is not NULL before rendering HTML
    HTML(input$description_unformatted)
  })
  
  # Save changes made by the user and reload data from CSV file
  observeEvent(input$save, {
    req(filtered_data()) # Ensure filtered data is available
    
    lang_col_title <- paste0("title_", input$language)       # Column name for title in selected language
    lang_col_description <- paste0("description_", input$language) # Column name for description in selected language
    
    updated_translations <- translations_rv()
    
    # Update the relevant row and column with user-provided values
    updated_translations[updated_translations$title_id == input$title_id, lang_col_title] <- input$title_unformatted
    updated_translations[updated_translations$title_id == input$title_id, lang_col_description] <- input$description_unformatted
    
    # Save updated data back to CSV file
    write_csv2(updated_translations, "../data/output/UAT_direct/translations.csv")
    
    # Store current selections to preserve them after reload
    current_title_id(input$title_id)
    current_language(input$language)
    
    # Reload data from CSV file and update reactive value
    new_translations <- load_data()
    translations_rv(new_translations)
    
    # Show a success message to confirm changes were saved successfully
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
