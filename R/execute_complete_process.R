#' Causality extraction process
#'
#' Executes the complete causality extraction process.
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
  # For R CMD Checks
  causal_relationship <- causality_pred <- cause <- effect <- file_name <- NULL
  h_id <- hypothesis <- hypothesis_num <- NULL

  # Generate File or List of Files
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

  # Initialize
  lst_output <- vector(
    mode   = "list",
    length = length(pdf_paths)
    )
  i = 1
  for (pdf in pdf_paths) {

    file_name <- basename(pdf)

    ## Text Pre-processing
    ### Wrap in tryCatch to catch failed pdf to text conversions
    possible_error <- tryCatch({
      text_processed <- process_text(pdf)

    },
    error = function(e) {
      e
      error_statement <- paste0("Error. File ",
                                file_name,
                                " could not be converted into text.")
      message(error_statement)

    }
    )

    ### Skip processing if error observed
    if(inherits(possible_error, "error")) next

    ## Hypothesis Classification
    hypothesis_df <- hypothesis_extraction(text_processed, apply_model = FALSE)

    # Test if empty
    hypothesis_empty_check <- hypothesis_df %>%
      dplyr::pull(hypothesis)

    hypothesis_empty <- purrr::is_empty(hypothesis_empty_check)

    if (!(hypothesis_empty)) {
      ## Entity extraction
      entities <- entity_extraction(hypothesis_df)

      # Test if empty
      empty_entity_check <- entities %>%
        tidyr::drop_na() %>%
        dplyr::pull(cause)

      entity_empty <- purrr::is_empty(empty_entity_check)

      if (!(entity_empty)) {
        ## Causality classification
        causality_class <- causality_classification(hypothesis_df)
        causality_class <- data.frame(causality_class)

        # Compile table
        iter_df <- cbind(hypothesis_df, entities) %>%
          tidyr::drop_na()
        iter_df <- cbind(iter_df, causality_class)
        iter_df$file_name <- file_name

        # Modify Headers and Format
        iter_df <- iter_df %>%
          dplyr::rename(
            hypothesis_num = h_id,
            causal_relationship = causality_pred
          ) %>%
          dplyr::select(
            file_name, hypothesis_num, hypothesis, cause,
            effect, causal_relationship
          ) %>%
          purrr::modify_if(is.factor, as.character)

        # Store in List
        lst_output[[i]] <- iter_df
        i <- i + 1
      }
    } else {
      no_hypothesis<- paste("File ",file_name ,": Hypothesis not detected.")
      message(no_hypothesis)
      next
    }

    pdf_complete_message <- paste("File ", file_name,": Complete")
    message(pdf_complete_message)
  }

  # Group Output Table for All Files into one table
  output_df <- dplyr::bind_rows(lst_output)

  print(output_df)

  # Remove causality predictions if both entities are not generated
  output_df <- remove_causality_pred(output_df)

  print(output_df)

  output_df

}
