# Import Hypothesis Classification model
get_path_ft_model <- function() {
  system.file("extdata", "models","fasttext_model.bin",
              package = 'CausalityExtraction')
}

ft_model <- fastTextR::ft_load(get_path_ft_model())

# REGEX Strings ---------------------------------------------------------------
split_tag <- "<split>"
hypothesis_tag <- "hypo (.*?):\\s*"
hypothesis_split_tag <- paste(split_tag, hypothesis_tag, sep = "")

# Functions -------------------------------------------------------------------

#' Generate fastText model input
#'
#' Performs pre-processing steps to prepare fastText model input.
#'
#' @param input_text input text for processing, character vector
#' @noRd

gen_fasttext_model_input <- function(input_text) {
  # For R CMD Checks
  output_text <-  NULL

  # Remove hypothesis tag
  output_text <- gsub(
    pattern     = hypothesis_tag,
    replacement = "",
    x           =  input_text
  )

  # Return output
  output_text

}



#' Filter hypothesis statements with fastText classification model
#'
#' Removes statements if not classified as hypothesis by the
#' hypothesis classification model.
#'
#' @param input_text possible hypothesis statements, character vector
#' @noRd

apply_fasttext_model <- function(input_text) {
  # For R CMD Checks
  col_names <- no <- Response <- yes <- NULL

  # Process model input data
  model_input <- gen_fasttext_model_input(input_text)

  # Generate hypothesis predictions
  hypothesis_pred <- fastTextR::ft_predict(
    model   = ft_model,
    newdata = model_input,
    rval    = "dense"
  ) %>%
    as.data.frame()

  # Rename columns
  col_names <- names(hypothesis_pred)

  if ("__label__1" %in% col_names) {
    hypothesis_pred <- hypothesis_pred %>%
      dplyr::rename(yes = "__label__1")
  }

  if ("__label__0" %in% col_names) {
    hypothesis_pred <- hypothesis_pred %>%
      dplyr::rename(no = "__label__0")
  }

  # Generate logical vector indicting if a vector element is a hypothesis

  col_names <- names(hypothesis_pred)

  ## If no column not found, all elements are hypothesis
  if (!("no" %in% col_names)) {
    response <- vector(
      mode   = "logical",
      length = length(model_input)
    )

    for (i in seq_along(model_input)) (response[i] <- TRUE)

    ## If yes column not found, all elements are not hypothesis
  } else if (!("yes" %in% col_names)) {
    response <- vector(
      mode   = "logical",
      length = length(model_input))

    for (i in seq_along(model_input)) (response[i] <- FALSE)

  } else {
    response <- hypothesis_pred %>%
      dplyr::mutate(
        Response = dplyr::if_else(
          condition = yes >= no,
          true      = TRUE,
          false     = FALSE
        )
      ) %>%
      dplyr::pull(Response)

  }

  # Return filtered input hypothesis statements with logical vector
  input_text[response]
}


#' Reduce to unique hypothesis labels
#'
#' Reduces the list of identified hypotheses to unique labels. This also
#' includes dropping any numeric hypothesis label where an alphanumeric label
#' with the same number has appeared earlier in the document, i.e.: If
#' Hypothesis 1 appears after Hypothesis 1a, Hypothesis 1 is removed
#'
#' @param hypothesis_labels Vector of identified hypothesis labels

unique_hypothesis_labels <- function(hypothesis_labels) {
  h_id <- hypothesis <- NULL

  regex_return_num <- "(\\d)+"

  hypothesis_numbers <- stringr::str_extract(
    string = hypothesis_labels,
    pattern = regex_return_num
  )

  # Check if hypothesis label contains letters
  logical_hypothesis_labels_alpha <- grepl("[a-zA-Z]", hypothesis_labels)

  # Initialize
  h_num_output <- c()
  h_label_output <- c()

  for (i in seq_along(logical_hypothesis_labels_alpha)) {

    # Extract values at index i
    h_label_alpha <- logical_hypothesis_labels_alpha[i]
    h_num <- hypothesis_numbers[i]
    h_label <- hypothesis_labels[i]

    # If label contains a letter
    if (h_label_alpha) {

      # Check if number already used in label
      if (!(h_num %in% h_label_output)) {

        h_label_output <- c(h_label_output, h_label)
        h_num_output <- c(h_num_output, h_num)

      }

    } else {

      if (!(h_num %in% h_num_output)) {

        h_label_output <- c(h_label_output, h_label)
        h_num_output <- c(h_num_output, h_num)

      }
    }

    h_label_output <- stringr::str_sort(x = h_label_output, numeric = TRUE)

  }

  # Return
  h_label_output

}


#' Drop hypothesis sentences with fewer than minimum token threshold
#'
#' Removes sentences that contain a hypothesis tag, and contain fewer than
#' the minimum threshold of tokens. This is a method to assist in removing
#' erroneous hypothesis identification.
#'
#' @param input_text Processed input text, one sentence per vector element
#' @param min_threshold Minimum threshold of tokens in a sentence.

drop_hypothesis_below_min_threshold <- function(
  input_text,
  min_threshold = 5
) {
  # For R CMD Checks
  extract_hypothesis <- index <- n <- n_tokens <- pass <- token <- NULL

  # Remove hypothesis tag and trim white space
  extract_hypothesis <- input_text %>%
    stringr::str_remove_all(pattern = hypothesis_tag) %>%
    stringr::str_trim()

  # Create tibble and add index
  hypothesis.tb <- dplyr::tibble(extract_hypothesis) %>%
    dplyr::mutate(
      index = dplyr::row_number()
    )

  # Insert dummy token for observations with zero tokens to avoid NA drop
  hypothesis.tb <- hypothesis.tb %>%
    dplyr::mutate(
      extract_hypothesis = dplyr::if_else(
        condition = extract_hypothesis == "",
        true      = "dummy",
        false     = extract_hypothesis
        )
    )

  # Generate vector of sentences with token counts above minimum threshold
  idx_above_min_threshold <- hypothesis.tb %>%
    tidytext::unnest_tokens(                          # Convert to tokens
      output = token,
      input  = extract_hypothesis
    ) %>%
    dplyr::group_by(index) %>%
    dplyr::summarise(n_tokens = dplyr::n()) %>%      # Count tokens per index
    dplyr::ungroup() %>%
    dplyr::mutate(
      pass = dplyr::if_else(                          # ID index pass/fail
        condition = n_tokens > min_threshold,
        true      = 1,
        false     = 0
      )
    ) %>%
    dplyr::filter(pass == 1) %>%                      # Filter passing index
    dplyr::pull(index)                                # Extract as vector

  # Return hypothesis statements with token count greater than threshold
  input_text[idx_above_min_threshold]

}


#' Extract hypothesis statements
#'
#' Wrapper function. Executes all steps in the hypothesis extraction process.
#'
#' @param input_text PDF text as processed by [process_text()].
#' @param apply_model Boolean tag for whether to filter hypothesis statements
#'  with the hypothesis classification model.

hypothesis_extraction <- function(input_text, apply_model = FALSE){
  # For R CMD Checks
  h_id <- hypothesis <- NULL

  # Reduce to Hypothesis Statements --------------------------------------------
  # Split vector elements with multiple hypothesis tags
  split_text <- stringr::str_split(
    string  = input_text,
    pattern = split_tag) %>%
    unlist()

  # Select vector elements which contain hypothesis tags
  logical_hypothesis_tag <- stringr::str_detect(
    string  = split_text,
    pattern = hypothesis_tag
  )

  hypothesis <- split_text[logical_hypothesis_tag]

  # Remove vector elements with token counts below minimum threshold
  hypothesis <- drop_hypothesis_below_min_threshold(hypothesis)

  # Filter vector elements based on hypothesis prediction model
  if (apply_model) {
    if (!(purrr::is_empty(hypothesis))) {

      hypothesis <- apply_fasttext_model(hypothesis)

    }
  }

  # Extract hypotheses label/number
  h_match <- hypothesis %>%
    stringr::str_match(
      pattern = hypothesis_tag
    )

  h_match_num <- h_match[,2]

  # Identify unique hypothesis numbers
  h_match_num_unq <- unique(h_match_num)

  # Remove known erroneous hypothesis formats
  error_hypothesis <- c("na")
  h_match_num_unq <- setdiff(h_match_num_unq, error_hypothesis)

  # Drop NA
  h_match_num_unq <- h_match_num_unq[!is.na(h_match_num_unq)]

  # Determine unique hypothesis label/numbers
  ## i.e.: Hypothesis 1 not selected if Hypothesis 1a appears earlier
  h_match_num_unq <- unique_hypothesis_labels(h_match_num_unq)


  # Determine vector index of initial hypothesis statements
  h_initial <- c()

  for (i in h_match_num_unq){

    intial_idx <- tapply(
      X     = seq_along(h_match_num),
      INDEX = h_match_num,
      FUN   = min
      )[i]

    h_initial <- c(h_initial, intial_idx)
  }

  # Reduce to only initial hypothesis instances
  hypothesis <- hypothesis[h_initial]

  # Create Output Table -------------------------------------------------------
  # Extract hypothesis label/number
  h_id <- hypothesis %>%
    stringr::str_extract("hypo (.*?):") %>%
    stringr::str_remove_all("hypo ") %>%
    stringr::str_remove_all(":")

  # Drop ~Hypo #:~ for entity extraction input
  hypothesis <- gsub(
    pattern     = "hypo (.*?):\\s*",
    replacement = "",
    x           =  hypothesis
    )

  # Create Dataframe with hypothesis number and hypothesis
  df_hypothesis <- data.frame(
    h_id,
    hypothesis,
    stringsAsFactors = FALSE
  )

  # Rename and add Hypothesis Number
  df_hypothesis <- df_hypothesis %>%
    dplyr::mutate(
      h_id = paste0("h_", h_id)
    ) %>%
    dplyr::select(h_id, hypothesis)

  df_hypothesis

}
