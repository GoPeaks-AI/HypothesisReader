#' Causality Extraction Shiny App
#'
#' Shiny app for generating output tables with CausalityExtraction function.
#' Designed to run locally on the users machine.
#'
#' @noRd

# Constants
process_report_message <- paste(
  "The following documents did not yield extracted hypoteses/propositions. "
  )

empty_table <- paste(
  "No records to display. ",
  "See Process Status Report for details.",
  sep = ""
)



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
            width: calc(20%);
            font-size: 2vw;
             }"
      ),
      shiny::HTML(
        "#missing_file_message_html{
          font-size: 14px;
          }"
      ),
      shiny::HTML(
        "ul {
          padding-left: 2.1em;
          list-style-type: square;
        }"
      )
    )
  ),
  shinyjs::useShinyjs(),
  shiny::titlePanel("Causal Knowledge Extraction"),
  shiny::fluidRow(
    ### SIDE
    shiny::column(
      width = 4,
      shiny::wellPanel(
        shiny::fileInput(
          inputId  = "file",
          label    = "Upload PDF File(s)",
          multiple = TRUE,
          accept   = c(".pdf"),
          width    = '90%'
        )
      ),
      shinyjs::hidden(
        shiny::wellPanel(
          id="panel_missing_files",
          shiny::titlePanel("Process Status Report"),
          # shiny::h5(process_report_message),
          shiny::htmlOutput(outputId = "missing_file_message_html")
        )
      )
    ),
    ### MAIN
    shiny::column(
      width = 8,
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


# Server -----------------------------------------------------------------------
server <- function(input, output) {
  # Set local app options
  set_options()

  # --- Reactive Values ---------------------------------------------------- #

  # Generate CausalityExtraction output table
  causality_extraction_output <- shiny::reactive({
    # Wait until file is uploaded
    shiny::req(input$file)

    # Execute package
    output_list <- gen_causality_extraction_output(input$file)

    output_list
  })


  # --- Outputs to UI ----------------------------------------------------------
  # Hide/Show
  ## Table download button
  shiny::observe({
    shinyjs::hide("download_table")

    output_list <- causality_extraction_output()
    output_table <- output_list[["table"]]

    if((nrow(output_table) != 0)) {
      shinyjs::show("download_table")
    }
  })

  ## Panel - hypothesis not detected
  shiny::observe({

    output_list <- causality_extraction_output()

    # Import Lists of files that are not included in output table
    h_files <- output_list[["file_names"]][["hypothesis"]]
    pdf2_text_files <- output_list[["file_names"]][["text"]]

    # Check to see if vectors are empty
    h_files_not_empty <- !(purrr::is_empty(h_files))
    pdf2_text_files_not_empty <- !(purrr::is_empty(pdf2_text_files))

    if(h_files_not_empty || pdf2_text_files_not_empty) {
      shinyjs::show(id="panel_missing_files")
    } else {
      shinyjs::hide(id="panel_missing_files")
    }
  })

  # Display output table
  output$causality_extraction_table <- DT::renderDT({
    output_list <- causality_extraction_output()
    output_table <- output_list[["table"]]

    output_table

  }, options =
    list(
      searching = FALSE,
      paging = FALSE,
      language = list(
        emptyTable = empty_table
        )
      )
  )

  # Display list of inputs not in output table
  output$missing_file_message_html<- shiny::renderUI({
    output_list <- causality_extraction_output()

    # Extract lists of files
    files <- output_list[["file_names"]]

    # Define intro messages
    intro_messages <- list(
      "text" = "File(s) did not successfully convert to text:" ,
      "hypothesis" = "Hypothesis/Proposition(s) were not detected:",
      "success" = "Process successfully complete:"
    )

     # Define conditions detected during process
    conditions_detected <- names(files)

    # Initialize output vector
    output_html <- c()

    # Generate html string

    for (condition in conditions_detected){

      # Ignore successful files
      if (condition == "success") next

      message <- intro_messages[[condition]]
      file_names <- files[[condition]]

      # Generate output html
      html_string <- gen_file_message_html(
        message = message,
        files   = file_names
        )

      # Append to list
      output_html <- c(output_html, html_string)
    }
    shiny::HTML(output_html)
  })

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

      output_list <- causality_extraction_output()
      output_table <- output_list[["table"]]

      vroom::vroom_write(
        output_table,
        file,
        delim = ",",
        bom   = TRUE)
    }
  )

}

#' Launch CausalityExtraction Shiny app
#'
#' Launches the CausalityExtraction shiny app. Runs locally on the users
#' machine.
#'
#'@export

LaunchApp <- function() {

  # Load shinyjs
  shinyjs::useShinyjs()

  # Run the application
  shiny::runApp(list(ui = ui, server = server),
                launch.browser = TRUE)
}
