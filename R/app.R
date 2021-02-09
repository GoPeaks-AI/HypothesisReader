#' Causality Extraction Shiny App
#'
#' Shiny app for generating output tables with CausalityExtraction function.
#' Designed to run locally on the users machine.
#'
#' @noRd

# Constants
h_warning <- paste("Hypotheses were not extracted from the",
                   "following uploaded documents:")

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
            width: calc(20%);
            font-size: 2vw;
             }"
      ),
      shiny::HTML("#no_hypothesis_html_list{
           font-size: 14px;
           font-style: italic;
           }"
      ),
      shiny::HTML("ul {
      padding-left: 1.1em;
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
          id="panel_no_hypothesis",
          shiny::titlePanel("Note"),
          shiny::h5(h_warning),
          shiny::htmlOutput(outputId = "no_hypothesis_html_list")
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
  # --- Reactive Values ---------------------------------------------------- #

  # Generate CausalityExtraction output table
  causality_extraction_output <- shiny::reactive({
    # Wait until file is uploaded
    shiny::req(input$file)

    # Execute package
    output_list <- gen_causality_extraction_output(input$file)

    output_table <- output_list[[2]]

    # Verify that hypothesis was detected
    if ((purrr::is_empty(output_table))) {

      shiny::showNotification(
        ui = "No Hypotheses Detected",
        duration = 30,
        type = "message"
      )
    }
    output_list
  })

  # Generate list of documents that did not return a hypothesis statement
  docs_wo_hypothesis <- shiny::reactive({

    docs_w_hypothesis <- file_name <- file_name_pdf <- NULL

    output_list <- causality_extraction_output()

    # Generate tables
    lookup_table <- output_list[[1]]
    output_table <- output_list[[2]]

    # Define document sets
    all_documents <- lookup_table %>%
      dplyr::pull(file_name_pdf)

    if (!(purrr::is_empty(output_table))) {

      docs_w_hypothesis <- output_table %>%
        dplyr::select(file_name) %>%
        dplyr::distinct() %>%
        dplyr::pull()

      # Determine documents loaded without hypothesis
      docs_wo_hypothesis <- setdiff(all_documents, docs_w_hypothesis)

    } else (docs_wo_hypothesis <- all_documents)

    docs_wo_hypothesis

  })


  # --- Outputs to UI ----------------------------------------------------------
  # Hide/Show download button
  shiny::observe({
    shinyjs::hide("download_table")

    output_list <- causality_extraction_output()
    output_table <- output_list[[2]]

    if(!(purrr::is_empty(output_table))) {
      shinyjs::show("download_table")
    }
  })

  # Hide/Show no hypothesis detected
  shiny::observe({
    if(!(purrr::is_empty(docs_wo_hypothesis()))) {
      shinyjs::show(id="panel_no_hypothesis")
    } else {
      shinyjs::hide(id="panel_no_hypothesis")
    }
  })

  # Display output table
  output$causality_extraction_table <- DT::renderDT({
    output_list <- causality_extraction_output()
    output_table <- output_list[[2]]
    output_table
  })

  # Display documents without hypotheses
  output$no_hypothesis_html_list<- shiny::renderUI({
    input.v <- docs_wo_hypothesis()

    # Generate HMTL list format
    output_html <- knitr::combine_words(
      words = input.v,
      before = '<li>',
      after = "</li>",
      and = " ",
      sep = " ")

    output_html <- paste("<ul>", output_html, "</ul>", sep = " ")

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
      output_table <- output_list[[2]]

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

launch_app <- function() {

  # Run the application

  shiny::runApp(list(ui = ui, server = server),
                launch.browser = TRUE)
}
