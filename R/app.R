#' Causality Extraction Shiny App
#'
#' Shiny app for generating output tables with CausalityExtraction function.
#' Designed to run locally on the users machine.
#'
#' @noRd


# OPTIONS
options(shiny.maxRequestSize = 10000*1024^2)

# UI ---------------------------------------------------------------------------
ui <- shiny::fluidPage(
  shiny::tags$head(
    shiny::tags$style(
    shiny::HTML("#shiny-notification-panel {
            top: calc(25%);
            bottom: unset;
            left: 0;
            right: 0;
            margin-left: auto;
            margin-right: auto;
            width: calc(25%);
            font-size: 2vw;
             }
             "
    )
    )
  ),
  shiny::titlePanel("Causal Knowledge Extraction"),
  # SIDEBAR
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::fileInput(
        inputId  = "file",
        label    = "Upload PDF File(s)",
        multiple = TRUE,
        accept   = c(".pdf"),
        width    = '90%'
      )
    ),
    # MAIN
    shiny::mainPanel(
      shiny::fluidRow(
        shiny::column(
          width = 12,
          shinycssloaders::withSpinner(
            ui_element = DT::DTOutput("causality_extraction_table"),
            type       = 1,
            size       = 3
            ),
          shiny::downloadButton(
            outputId = "download_table",
            label    = "Download")
          )
        )
      )
    )
  )

# Define server logic required to draw a histogram
# Server -----------------------------------------------------------------------
server <- function(input, output) {
  # --- Reactive Values ---------------------------------------------------- #

  # Generate CausalityExtraction output table
  causality_extraction_table <- shiny::reactive({
    # Wait until file is uploaded
    shiny::req(input$file)

    # Execute package
    output_table <- gen_causality_extraction_table(input$file)

    # Verify that hypothesis was detected
    if (!(purrr::is_empty(output_table))) {

      output_table

    } else {

      shiny::showNotification(
        ui = "No Hypotheses Detected",
        duration = 30,
        type = "message"
        )
      NULL

    }
  })


  # --- Outputs to UI ----------------------------------------------------------
  # Display output table
  output$causality_extraction_table <- DT::renderDT(
    causality_extraction_table()
    )


  # --- Download ---------------------------------------------------------------
  output$download_table <- shiny::downloadHandler(
    filename = function() {
      paste(
        "causality_extraction_",
        Sys.Date(),
        ".csv",
        sep = ""
        )
    },
    content = function(file) {
      vroom::vroom_write(
        causality_extraction_table(),
        file, delim = ",")
    }
  )

}

#' Launch CausalityExtraction Shiny app
#'
#' Launches the CausalityExtraction shiny app. Runs locally on the users
#' machine.
#'
#'@export

launch_app <- function() {

  # Run the application

  shiny::runApp(list(ui = ui, server = server),
                   launch.browser = TRUE)
}
