#' Message to console
#'
#' Outputs formatted message to console
#'
#' @param file_names Character vector of files names
#' @param message String of message
#'
#' @noRd

output_message <- function(file_names, message) {
  # For RMD Checks

  # Apply new line and spaces to file names
  file_names <- paste("  ", file_names, "\n")

  # Define message text
  text <- paste0(
    message,
    "\n",
    collapse = ""
  )

  # Concatenate file names
  file_names <- paste0(
    file_names,
    collapse = ""
  )

  # Combine text with file names
  output_message <- paste(
    text,
    file_names,
    sep = ""
    )

  # Send message to console
  message(output_message)

}

#' Compile final table
#'
#' Compiles all calculated values into single table
#'
#' @param hypothesis Output of [hypothesis_extraction()]
#' @param entities Output of [entity_extraction()]
#' @param causality Output of [causality_classification()]
#' @param direction Output of [direction_classification()]
#' @param file_name File name of processed PDFs
#'
#' @noRd

compile_table <- function(hypothesis, entities, causality,
                          direction, file_name) {
  # For R CMD Checks
  causal_relationship <- cause <- effect <- causality_pred <- NULL
  direction_pred <- h_id <- hypothesis_num <- iter.df <- NULL

  # Bind hypothesis and entities
  iter.df <- cbind(hypothesis, entities) %>%
    tidyr::drop_na()

  # Bind causality and direction
  iter.df <- cbind(iter.df, causality, direction)

  # Add file name
  iter.df$file_name <- file_name

  # Modify Headers and Format
  iter.df <- iter.df %>%
    dplyr::rename(
      hypothesis_num = h_id,
      causal_relationship = causality_pred,
      direction = direction_pred
    ) %>%
    dplyr::select(
      file_name, hypothesis_num, hypothesis, cause,
      effect, direction, causal_relationship
    ) %>%
    purrr::modify_if(is.factor, as.character)

  iter.df
}


#' Causality extraction process - All Outputs
#'
#' Executes the complete causality extraction process. This function outputs
#'  the causality extraction output table as well as lists of input files
#'  which failed to convert to text, and which did not contain any hypotheses.
#'
#' @param file_path Path or character vector of paths to PDF documents to be
#'  processed.This parameter or **folder_path** must be provided. If both
#'  parameters are provided, the input in this parameter will be processed and
#'  **folder_path** will be ignored.
#'
#' @param folder_path Path to folder containing PDF documents to be
#'  processed. All PDF documents in the folder specified will be processed.
#'  This call is not recursive, so no PDF documents in sub-folders will be
#'  processed. This parameter or **file_path** must be provided. If both
#'  parameters are provided, the input in **file_path** will be processed and
#'  this parameter will be ignored.
#'
#' @param file_names (Optional) Character vector of file names. This parameter
#'  provides names for each file. This is to be used primarily to pass the
#'  correct file name when using the shiny app. Shiny renames the file names
#'  inside file paths after upload.
#'
#'
#'@noRd


causality_extraction_complete <- function(
  file_path = NULL,
  folder_path = NULL,
  file_names = NULL
  ) {
  # For R CMD Checks
  causal_relationship <- causality_pred <- cause <- direction <-  NULL
  direction_pred <- effect <- error <- file_name <-  NULL
  file_names_hy_not_detected <- file_names_text_conv_fail <- h_id <- NULL
  hypothesis <- hypothesis_num <- remove_pred_flag <- text_raw <- NULL
  variable_1 <- variable_2 <- NULL

  # Create File List -----------------------------------------------------------
  pdf_path <- c()
  if (is.not.null(file_path)){
    pdf_paths <- file_path

  } else if (is.not.null(folder_path)) {

    pdf_paths <- list.files(recursive = FALSE,
                            path = folder_path,
                            pattern = ".pdf",
                            full.names = TRUE)

  } else (
    warning("File name(s) or folder path required.")
  )

  # Create vector of file names if necessary
  if (is.null(file_names)){
    file_names <- basename(pdf_paths)
  }

  # Convert PDF to Text --------------------------------------------------------
  text_raw <- pdf_to_text(pdf_paths)

  # Check for failed text conversion
  idx_pdf2text_fail <- text_conversion_test(text_raw)

  # Create vector of file names which did not convert
  text_idx_range <- 1:length(text_raw)
  log_pdf2text <- !(text_idx_range %in% idx_pdf2text_fail)
  names_pdf2text_fail <- file_names[!log_pdf2text]

  # Drop files names and extracted text if conversion failed
  text_raw <- text_raw[log_pdf2text]
  file_names <- file_names[log_pdf2text]

  # Causality Extraction Process -----------------------------------------------
  message("")
  message("Causality Extraction Process: Start")

  # Initialize output vector
  lst_output <- vector(
    mode   = "list",
    length = length(text_raw)
    )

  # Initialize vectors for output messages
  names_h_detect_fail <- c()
  names_process_complete <- c()

  for (i in seq_along(text_raw)) {

    # Define text and file name
    text <- text_raw[i]
    file_name <- file_names[i]

    # Process raw text
    text_processed <- process_text(text)

    # Hypothesis Classification
    hypothesis.df <- hypothesis_extraction(text_processed, apply_model = FALSE)

    # Test if hypothesis detected
    hypothesis_detect_test <- hypothesis.df %>%
      dplyr::pull(hypothesis)

    hypothesis_detected <- !(purrr::is_empty(hypothesis_detect_test))

    if (hypothesis_detected) {
      # Entity extraction
      entities <- entity_extraction(hypothesis.df)

      # Causality classification
      causality_class <- causality_classification(hypothesis.df)
      causality_class <- data.frame(causality_class)

      # Direction class
      direction_class <- direction_classification(hypothesis.df)
      direction_class <- data.frame(direction_class)

      # Compile table
      iter.df <- compile_table(
        hypothesis = hypothesis.df,
        entities   = entities,
        causality  = causality_class,
        direction  = direction_class,
        file_name  = file_name
        )

      # Extract hypothesis tag
      iter.df <- iter.df %>%
        dplyr::mutate(
          hypothesis = gsub(
            pattern = "hypo (.*?):\\s*",
            replacement = "",
            x = hypothesis
          )
        )

      # Remove trailing commas from cause, effect (for aesthetics)
      iter.df$cause <- gsub(",$", "", iter.df$cause)
      iter.df$effect <- gsub(",$", "", iter.df$effect)

      # Store in List
      lst_output[[i]] <- iter.df

      # Store file name
      names_process_complete <- c(names_process_complete, file_name)

     message(file_name)

    } else {
      # Store file name
      names_h_detect_fail <- c(names_h_detect_fail, file_name)

      message(file_name)
    }
  }

  message("Causality Extraction Process: Complete")

  # Output messages to console
  ## Define messages
  message.v <- c(
    "File(s) did not successfully convert to text:",
    "Hypothesis/Proposition(s) were not detected:",
    "Process successfully complete:"
  )

  ## Define file name vector list
  list_file_names <- list(
    "text" = names_pdf2text_fail,
    "hypothesis" = names_h_detect_fail,
    "success" = names_process_complete
  )

  message("")
  message("PROCESS STATUS REPORT")
  # Output messages
  for (i in seq_along(message.v)) {

    file_names <- list_file_names[[i]]

    if (!(purrr::is_empty(file_names))){

      output_message(
        message = message.v[i],
        file_names = list_file_names[[i]]
      )
      }
    }

  # Group Output Table for All Files into one table
  output_df <- dplyr::bind_rows(lst_output)

  # Replace if dataframe is empty (for shiny output)
  if (nrow(output_df) != 0) {

    # Set to False because we are not using entity extraction in causality
    # models
    remove_pred_flag <- FALSE
    if (remove_pred_flag) {
      # Remove causality predictions if both entities are not generated
      output_df <- remove_pred(output_df)
    }

    # Rename entity columns
    output_df <- output_df %>%
      dplyr::rename(
        variable_1 = cause,
        variable_2 = effect
      )
  } else {

    output_df <- data.frame(
      file_name = character(),
      hypothesis_num = character(),
      hypothesis = character(),
      variable_1 = character(),
      variable_2 = character(),
      direction = character(),
      causal_relationship = character(),
      stringsAsFactors=FALSE
    )
  }

  output_list <-
    list(
      "table" = output_df,
      "file_names" = list_file_names
    )

  output_list

}



#' Causality extraction process
#'
#' Executes the complete causality extraction process, returning a dataframe of
#'  extracted hypotheses, along with extracted entities, causality class, and
#'  direction class.
#'
#' @param file_path Path or character vector of paths to PDF documents to be
#'  processed.This parameter or **folder_path** must be provided. If both
#'  parameters are provided, the input in this parameter will be processed and
#'  **folder_path** will be ignored.
#'
#' @param folder_path Path to folder containing PDF documents to be
#'  processed. All PDF documents in the folder specified will be processed.
#'  This call is not recursive, so no PDF documents in sub-folders will be
#'  processed. This parameter or **file_path** must be provided. If both
#'  parameters are provided, the input in **file_path** will be processed and
#'  this parameter will be ignored.
#'
#'@export

CausalityExtraction <- function(file_path = NULL, folder_path = NULL) {

  output_results <- causality_extraction_complete(
    file_path   = file_path,
    folder_path = folder_path
    )

  output_table <- output_results[['table']]

  if (nrow(output_table) == 0) {
    warning("No hypothesis detected with input.")
    NA
  } else {
    output_table
  }

}
