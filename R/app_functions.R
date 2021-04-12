#' Generate HypothesisReader table
#'
#' Generate output table of the HypothesisReader function.
#'
#' @param file_properties shiny defined properties of uploaded files
#'
#' @noRd

gen_hypothesis_reader_output <- function(file_properties) {
  # For RMD Check
  file_names_pdf <- file_names_temp <- NULL

  # Define file paths and names
  file_paths <- file_properties$datapath
  file_names_pdf  <- basename(file_properties$name)
  file_names_temp <- basename(file_paths)

  # Generate output table, with temporary file names
  output_list <- hypothesis_reader_complete(
    file_path = file_paths,
    file_names = file_names_pdf
    )

  output_list

}


#' Set shiny app options
#'
#' Sets any local options for the shiny app.
#'
#' @noRd

set_options <- function() {
  # Upload File Size Limit
  file_size_mb = 10e3
  options(shiny.maxRequestSize = file_size_mb*1024^2)
}

#' Generate html for process status report message
#'
#' Generates the process status report in html format.
#'
#' @noRd


gen_file_message_html <- function(message, files){
  # Convert file names into list
  html_files <- knitr::combine_words(
    words = files,
    before = '<li>',
    after = "</li>",
    and = " ",
    sep = " ")

  # Apply italics to file list
  html_files <- paste(
    "<i>",
    html_files,
    "</i>",
    sep = " "
  )

  # Apply un-ordered list tag to list
  html_files <- paste(
    "<ul>",
    html_files,
    "</ul>",
    sep = " "
  )

  # Apply formatting to list preceding message
  html_message <- paste(
    "<b>",
    message,
    "</b>",
    sep = ""
  )

  # Combine message and list
  html_compile <- paste(
    html_message,
    html_files,
    sep = ""
  )

  # Encase in a section
  html_compile <- paste(
    "<section>",
    html_compile,
    "</section>",
    sep = ""
  )

  html_compile

}
