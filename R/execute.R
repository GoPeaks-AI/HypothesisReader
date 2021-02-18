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
  causal_relationship <- causality_pred <- cause <- direction <-  NULL
  direction_pred <- effect <- file_name <- h_id <- hypothesis <- NULL
  hypothesis_num <- variable_1 <- variable_2 <- NULL

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
        # Causality classification
        causality_class <- causality_classification(hypothesis_df)
        causality_class <- data.frame(causality_class)

        # Direction class
        direction_class <- direction_classification(hypothesis_df)
        direction_class <- data.frame(direction_class)

        # Compile table
        iter.df <- compile_table(
          hypothesis = hypothesis_df,
          entities   = entities,
          causality  = causality_class,
          direction  = direction_class,
          file_name  = file_name
          )

        # Remove trailing commas from cause, effect (for aesthetics)
        iter.df$cause <- gsub(",$", "", iter.df$cause)
        iter.df$effect <- gsub(",$", "", iter.df$effect)

        # Store in List
        lst_output[[i]] <- iter.df
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

  # Remove causality predictions if both entities are not generated
  output_df <- remove_pred(output_df)

  # Rename entity columns
  output_df %>%
    dplyr::rename(
      variable_1 = cause,
      variable_2 = effect
    )

  output_df

}
