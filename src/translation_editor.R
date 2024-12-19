library(shiny)
library(dplyr)
library(readr)
library(htmltools)

# Function to get the current branch
get_current_branch <- function() {
  branch <- system("git rev-parse --abbrev-ref HEAD", intern = TRUE)  # Default to "uat" if not set
  return(branch)
}

# Load the data
current_branch <- get_current_branch()
data_url <- paste0("https://raw.githubusercontent.com/inbo/aspbo/", current_branch, "/data/output/UAT_direct/translations.csv")
translations <- read.csv2(data_url)

# Check column names and print them
print(colnames(translations))

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
  
  # Update title_id choices after data is loaded
  observe({
    req(translations)
    updateSelectInput(session, "title_id", choices = unique(translations$title_id))
  })
  
  # Reactive expression to filter data based on selected title_id
  filtered_data <- reactive({
    req(input$title_id)
    translations %>% filter(title_id == input$title_id)
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
  
  # Save changes back to the CSV file (placeholder functionality)
  observeEvent(input$save, {
    req(filtered_data())
    
    # Update the translations data frame with the new values
    lang_col_title <- paste0("title_", input$language)
    lang_col_description <- paste0("description_", input$language)
    
    translations[translations$title_id == input$title_id, lang_col_title] <<- input$title_unformatted
    translations[translations$title_id == input$title_id, lang_col_description] <<- input$description_unformatted
    
    # Save to CSV (this will overwrite the existing file; adjust as needed)
    write_csv2(translations, "translations.csv")
    
    showModal(modalDialog(
      title = "Success",
      "Changes have been saved successfully!",
      easyClose = TRUE,
      footer = NULL
    ))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
