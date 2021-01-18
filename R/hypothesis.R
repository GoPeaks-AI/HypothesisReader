# Import Hypothesis Classification model
get_path_ft_model <- function() {
  system.file("extdata", "models","fasttext_model.bin",
              package = 'CausalityExtraction')
}

ft_model <- fastTextR::ft_load(get_path_ft_model())

# REGEX Strings ---------------------------------------------------------------
## Identify Hypo _ #:
regex_hypo_marker <- "<split>hypo (.*?):"

# Functions -------------------------------------------------------------------

#' Filter hypothesis statements with fastText classification model
#'
#' Removes hypothesis statements if not classified as hypothesis by the
#' hypothesis classification model.
#'
#' @param hypothesis_entity hypothesis statements in the format for the entity
#'  extraction step, character vector
#' @param hypothesis_causality hypothesis statements in the format for the
#'  causality classification step, character vector
#'
#' @noRd

apply_fasttext <- function(hypothesis_entity, hypothesis_causality) {
  # For R CMD Checks
  Response <- NULL

  # Verify hypothesis class with fastText model
  ## Generate hypothesis class prediction dataframe

  hypothesis_pred <- fastTextR::ft_predict(
    model   = ft_model,
    newdata = hypothesis_entity,
    rval    = "dense"
  ) %>%
    as.data.frame()

  ## Assign prediction column names
  col_names <- names(hypothesis_pred)

  ## Drop statements which were predicted as non-hypothesis class
  if (!("__label__0" %in% col_names)) {
    response <- vector(
      mode   = "logical",
      length = length(hypothesis_entity)
    )

    for (i in seq_along(hypothesis_entity)){
      response[i] <- TRUE

    }

  } else if (!("__label__1" %in% col_names)) {
    response <- vector(
      mode   = "logical",
      length = length(hypothesis_entity))

    for (i in seq_along(hypothesis_entity)){
      response[i] <- FALSE

    }
  } else {
    response <- hypothesis_pred %>%
      dplyr::mutate(
        Response = dplyr::if_else(
          condition = .[[1]] > .[[2]],
          true      =  FALSE,
          false     = TRUE
        )
      ) %>%
      dplyr::pull(Response)

  }

  # Filter hypothesis statement vectors with logicil vector
  hypothesis_causality <- hypothesis_causality[response]
  hypothesis_entity <- hypothesis_entity[response]

  # Assign to list for output
  output_hypothesis <- vector(
    mode   = "list",
    length = 2
  )

  output_hypothesis[[1]] <- hypothesis_causality
  output_hypothesis[[2]] <- hypothesis_entity

  output_hypothesis
}


#' Extract hypothesis statements
#'
#' Wrapper function. Executes all steps in the hypothesis extraction process.
#'
#' @param input_text PDF text as processed by [process_text()].
#' @param apply_model Boolean tag for whether to filter hypothesis statements
#'  with the hypothesis classification model.

hypothesis_extraction <- function(input_text, apply_model = TRUE){
  # For R CMD Checks
  h_id <- hypothesis <- NULL

  # Tokenize into sentences
  processing_text <- stringr::str_c(
    input_text,
    collapse = " "
  )

  processing_text <- tokenizers::tokenize_sentences(
    processing_text,
    strip_punct = FALSE) %>%
    unlist()

  # Replace double spaces
  processing_text <- stringr::str_replace_all(
    string      = processing_text,
    pattern     = "  ",
    replacement = " "
  )

  # Normalize text case
  processing_text <- tolower(processing_text)

  # Hypothesis Extraction -----------------------------------------------------
  # Identify lines with hypothesis pattern
  h_match <- processing_text %>%
    stringr::str_match(
      pattern = regex_hypo_marker
    )

  # Extract hypotheses number
  h_match_num <- h_match[,2]

  # Identify unique hypothesis numbers
  h_match_num_unq <- unique(h_match_num)

  # Drop NA
  h_match_num_unq <- h_match_num_unq[!is.na(h_match_num_unq)]

  # Determine vector index of initial hypothesis statements
  h_initial <- c()
  for (i in h_match_num_unq){
    intial_idx <- tapply(seq_along(h_match_num),
                         h_match_num,
                         min)[i]
    h_initial <- c(h_initial, intial_idx)
  }

  # Reduce text to only initial hypothesis instances
  h_statements <- processing_text[h_initial]

  # Split Statements On Indicator (Defined in Processing) ----------------------
  ## Define
  split_indicator <- "<split>"

  ## Split on indicator
  h_statements <- stringr::str_split(
    string  = h_statements,
    pattern = split_indicator) %>%
    unlist()

  ## Detect statements which contain "Hypo"
  logical_hypothesis_2 <- stringr::str_detect(
    string  = h_statements,
    pattern = "hypo"
  )

  ## Drop Statements that Do Not Include "Hypo"
  h_statements <- h_statements[logical_hypothesis_2]

  # Drop Duplicate Hypothesis Calls --------------------------------------------
  ## Extract hypothesis number
  h_number <- h_statements %>%
    stringr::str_extract("hypo (.*?):") %>%
    stringr::str_remove_all("hypo ") %>%
    stringr::str_remove_all(":") %>%
    as.integer()

  ## Identify Duplicate Hypothesis Numbers
  logical_hypothesis_3 <- vector(
    mode   = "logical",
    length = length(h_number)
  )

  h_tracker <- vector(
    mode   = "integer",
    length = length(h_number)
  )

  for (i in seq_along(h_number)) {
    num <- h_number[i]

    if (is.na(num)){
      logical_hypothesis_3[i] = FALSE
      h_tracker[i] <- -1

    } else if (num %in% h_tracker) {
      logical_hypothesis_3[i] = FALSE
      h_tracker[i] <- -1

    } else {
      logical_hypothesis_3[i] = TRUE
      h_tracker[i] <- num

    }
  }

  ## Drop duplicates and non-hypotheses
  h_statements <- h_statements[logical_hypothesis_3]

  # # Fix words split over new line
  # for (i in seq_along(word_split_error)) {
  #   # Select Incorrect and Fixed Words
  #   word_split <- word_split_error[i]
  #   word_fix <- str_replace_all(string = word_split,
  #                               pattern = " ",
  #                               replacement = "")
  #
  #   # Replace All Instances
  #   h_statements <- h_statements %>%
  #     str_replace_all(pattern = word_split,
  #                     replacement = word_fix)
  # }

  # Save current state for causality classification input
  hypothesis_causality <- h_statements

  # Drop ~Hypo #:~
  hypothesis_entity <- gsub(".*: ","", h_statements)

  # Filter with hypothesis classification model
  if (apply_model) {

    # Verify hypothesis statements are available
    if (!(purrr::is_empty(hypothesis_entity))) {

      output_hypothesis <- apply_fasttext(
        hypothesis_entity,
        hypothesis_causality
      )

      hypothesis_causality <- output_hypothesis[[1]]
      hypothesis_entity <- output_hypothesis[[2]]

    }
  }

  # Create Dataframe with Hypothesis Number and Hypothesis
  df_hypothesis <- data.frame(
    hypothesis_entity,
    hypothesis_causality,
    stringsAsFactors = FALSE
  )

  # Rename and add Hypothesis Number
  df_hypothesis <- df_hypothesis %>%
    dplyr::rename(
      hypothesis = hypothesis_entity
    ) %>%
    dplyr::mutate(
      h_id = paste0("h_", dplyr::row_number())
    ) %>%
    dplyr::select(h_id, hypothesis, hypothesis_causality)

  df_hypothesis

}
