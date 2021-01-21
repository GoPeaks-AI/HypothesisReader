#' Shiny app for generating output tables with CausalityExtraction function.
#' Designed to run locally on the users machine.


# OPTIONS
options(shiny.maxRequestSize = 100*1024^2)

# UI ---------------------------------------------------------------------------
ui <- shiny::fluidPage(

  shiny::titlePanel("Causal Knowledge Extraction"),
  # SIDEBAR
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::fileInput(
        inputId = "file1",
        label = "Upload PDF File(s)",
        multiple = TRUE,
        accept = c(".pdf"),
        width = '90%'
      )
    ),
    # MAIN
    shiny::mainPanel(
      shiny::fluidRow(
        shiny::column(
          width = 12,
          shinycssloaders::withSpinner(
            ui_element = DT::DTOutput("causality_extraction_table"),
            type = 1,
            size = 3
            )
          )
        )
      )
    )
  )

# Define server logic required to draw a histogram
# Server -----------------------------------------------------------------------
server <- function(input, output) {
  # --- Reactive Values ---------------------------------------------------- #

  # Convert Uploaded PDF to Text
  causality_extraction_table <- shiny::reactive({
    # Wait until file is uploaded
    shiny::req(input$file1)

    file_path <- input$file1$datapath

    # Execute package
    output_table <- CausalityExtraction(file_path = file_path)
  })



  # --- Outputs to UI ----------------------------------------------------------
  # Display output table
  output$causality_extraction_table <- DT::renderDT(
    causality_extraction_table()
  )

  observeEvent(input$file1, {
    print(paste0("File Path: ", input$file1$datapath))
    df_file_name <- data.frame(basename(input$file1$name))
    print(paste0(df_file_name))

  })

  # --- Download ---------------------------------------------------------------
  output$download <- downloadHandler(
    filename = function() {
      paste("causality_extraction_", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      vroom::vroom_write(tidied(), file)
    }
  )

}

# Run the application
shiny::shinyApp(ui = ui, server = server)
