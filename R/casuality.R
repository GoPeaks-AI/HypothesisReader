#' Functions -------------------------------------------------------------------
#'
#' Retrieve path to causality classification model
#'
#' Retrieves the path to the causality classification model. This prevents a
#' hard path being defined, which would cause an error when verifyin
#' staged installation.
#'
#' @noRd

get_path_causality_model <- function() {
  system.file("extdata", "models",
              "causality_bow_pipeline_logistic_regression.pkl",
              package = 'CausalityExtraction')
}

#' Load causality classification model
#'
#' Loads the causality classification model. Wrapped in memoise to avoid
#' repeated loading of the same model.
#'
#' @noRd

load_causality_model <- function() {
  model_causality <- NULL
  model_causality <- joblib$load(get_path_causality_model())
  model_causality
}

mem_load_causality_model <- memoise::memoise(load_causality_model)


#' Generate causality classification input
#'
#'
#' Processes the extracted hypothesis statements into the format for the
#' causality class model input.
#'
#' @param hypothesis hypothesis statement output of [hypothesis_extraction()]
#'
#' @noRd

gen_causality_model_input <- function(hypothesis_df) {
  # For R CMD Checks
  causal_statement <- cause <- effect  <- row_id <- sentence <- NULL
  word <- word_lemm <- NULL

  # Define regex
  pattern_punct <- "[[:punct:]]"

  # Generate Datasets ----------------------------------------------------------
  ## Extracted entities
  entities <- entity_extraction(hypothesis_df)

  ## Causality classification input
  hypothesis_causality <- hypothesis_df %>%
    dplyr::select(hypothesis_causality)

  # Text Processing ------------------------------------------------------------
  ##  Drop punctuation / replace entities w/ normalized tags
  causality_df <- hypothesis_causality %>%
    dplyr::bind_cols(entities) %>%
    dplyr::mutate(
      row_id= dplyr::row_number()
    ) %>%
    dplyr::select(row_id, dplyr::everything()) %>%
    tidyr::drop_na()  %>%
    dplyr::mutate(
      hypothesis_causality = stringr::str_remove_all(
        string  = hypothesis_causality,
        pattern = pattern_punct
      ),
      cause = stringr::str_remove_all(
        string  = cause,
        pattern = pattern_punct
      ),
      effect = stringr::str_remove_all(
        string  = effect,
        pattern = pattern_punct
      )
    ) %>%
    dplyr::mutate(
      causal_statement = stringr::str_replace(
        string      = hypothesis_causality,
        pattern     = cause,
        replacement = "node1"
      ),
      causal_statement = stringr::str_replace(
        string      = causal_statement,
        pattern     = effect,
        replacement = "node2"
      )
    )

  ## Remove stopwords
  causality_df <- causality_df %>%
    tidytext::unnest_tokens(word, causal_statement) %>%
    dplyr::anti_join(
      tidytext::get_stopwords(),
      by = "word"
    ) %>%
    dplyr::select(row_id, word)

  ## Lemmatize Words
  ### Extract words
  tokens <- causality_df %>%
    dplyr::pull(word)

  ### Initialize
  tokens_lemm <- vector(
    mode   = "character",
    length = length(tokens)
  )

  lemmatizer <- nltk_stem$WordNetLemmatizer()

  ### Execute Lemmatization
  for (i in seq_along(tokens)) {
    token = tokens[i]
    token_lemm <- lemmatizer$lemmatize(token)
    tokens_lemm[i] = token_lemm
  }

  ### Replace Lemmatized Words and Convert Tokens to Sentences as Vector
  model_input <- causality_df %>%
    dplyr::bind_cols(tokens_lemm) %>%
    dplyr::rename(word_lemm = "...3") %>%
    dplyr::group_by(row_id) %>%
    dplyr::mutate(
      sentence = stringr::str_c(
        word_lemm,
        collapse = " ")
    ) %>%
    dplyr::select(-word, -word_lemm) %>%
    dplyr::distinct() %>%
    dplyr::pull(sentence)

  model_input
}


#' Generate causality classification predictions
#'
#' Generates the causality classification predictions.
#'
#' @param model_input Output of [gen_causality_model_input()]
#'
#' @noRd
#

gen_causality_class <- function(model_input) {
  model_causality <- NULL

  # Load causality model
  model_causality <- mem_load_causality_model()

  # Convert to numpy array
  model_input_np <- np$array(model_input)

  # Generate predictions
  causality_pred <- model_causality$predict(model_input_np)

  causality_pred

}


#' Causality classification
#'
#' Wrapper function. Executes all steps in the causality classification process.
#'
#' @param hypothesis_df hypothesis statement output of [hypothesis_extraction()]
#'

causality_classification <- function(hypothesis_df) {
  # Process hypothesis into model input
  model_input <- gen_causality_model_input(hypothesis_df)

  # Generate causality predictions
  causality_pred <- gen_causality_class(model_input)

  causality <- data.frame(causality_pred)

  causality
}
