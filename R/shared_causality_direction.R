#' The following script contains functions related to the common processes for
#' the Causality and Direction classification models

#' Download wordnet library for NLTK lemmatizer
#'
#' Downloads the wordnet library from the NLTK python module. This function is
#' wrapper with **memoise** so that it is only executed once.
#'
#' @noRd

download_wordnet <- function() {
  # Captures NLTK download output message to prevent the user seeing it
  x <- reticulate::py_capture_output({
    nltk$download('wordnet')
  })
}

mem_download_wordnet <- memoise::memoise(download_wordnet)


#' Lemmatize tokens
#'
#' Lemmatizes a character vector of tokens using the Wordnet lemmatizer from the
#' python NLTK package.
#'
#' @param token Token from raw text
#'
#' @noRd

lemmatize <- Vectorize(
  function(token) {

    ### Initialize lemmatizer
    lemmatizer <- nltk_stem$WordNetLemmatizer()

    lemmatizer$lemmatize(token)
  }
)


#' Stem tokens
#'
#' Stems a character vector of tokens using the Snowball stemmer from the
#' python NLTK package.
#'
#' @param token Token from raw text
#'
#' @noRd

stem <- Vectorize(
  function(token) {

    ### Initialize stemmer
    stemmer <- nltk_stem$SnowballStemmer(language='english')

    stemmer$stem(token)
  }
)


#' Generate causality and direction classification input
#'
#' Processes the extracted hypothesis statements into the format for the
#' causality and direction classification models.
#'
#' @param hypothesis hypothesis statement output of [hypothesis_extraction()]
#' @param entity_extraction Boolean indicating if the cause and effect nodes
#'  should be replaced with normalized tags
#' @param token_method flag for selecting the method of token normalization to
#'  be applied to the text data, lemmatization or stemming
#'
#' @noRd

gen_causality_direction_model_input <- function(
  hypothesis_df,
  entity_extraction = TRUE,
  token_method = "lemm"
  ) {
  # For R CMD Checks
  causal_statement <- cause <- effect <- hypothesis <- row_id <- NULL
  sentence <- word <- word_lemm <- NULL

  # Constants
  ## Define regex
  pattern_punct <- "[[:punct:]]"

  ## Define replacement values
  missing_tag <- "<missing>"

  # Generate Datasets ----------------------------------------------------------
  ## Extracted entities
  entities <- entity_extraction(hypothesis_df)

  ## Raw input
  hypothesis <- hypothesis_df %>%
    dplyr::select(hypothesis)

  # Text Processing ------------------------------------------------------------
  ##  Drop punctuation & replace with normalized entity tags
  model_input.df <- hypothesis %>%
    dplyr::bind_cols(entities) %>%
    dplyr::mutate(
      row_id = dplyr::row_number()
    ) %>%
    dplyr::select(row_id, dplyr::everything()) %>%
    dplyr::mutate(
      hypothesis = stringr::str_remove_all(
        string  = hypothesis,
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
    dplyr::mutate(                               # Replace Missing With Tag
      cause   = dplyr::if_else(                  # Quiets warning to console
        condition = cause == "",
        true      =  missing_tag,
        false     = cause
      ),
      effect  = dplyr::if_else(
        condition = effect == "",
        true      =  missing_tag,
        false     = effect
      )
    )

  # Replace entity with node1/2 tag
  if (entity_extraction) {
    model_input.df <- model_input.df %>%
      dplyr::mutate(
        causal_statement = dplyr::if_else(
          condition = (cause != missing_tag),
          true = {
            stringr::str_replace(
              string      = hypothesis,
              pattern     = cause,
              replacement = "node1"
            )},
          false = hypothesis
        )
      ) %>%
      dplyr::mutate(
        causal_statement = dplyr::if_else(
          condition = (effect != missing_tag),
          true = {
            stringr::str_replace(
              string      = causal_statement,
              pattern     = effect,
              replacement = "node2"
            )},
          false = causal_statement
        )
      )
  } else {
    model_input.df <- model_input.df %>%
      dplyr::mutate(causal_statement = hypothesis)
  }


  ## Remove stopwords
  model_input.df <- model_input.df %>%
    tidytext::unnest_tokens(word, causal_statement) %>%
    dplyr::anti_join(
      tidytext::get_stopwords(),
      by = "word"
    ) %>%
    dplyr::select(row_id, word)

  ## Token normalization
  ### Extract words
  tokens <- model_input.df %>%
    dplyr::pull(word)

  ### Initialize
  tokens_norm <- vector(
    mode   = "character",
    length = length(tokens)
  )

  # Execute token normalization by lemming or stemming
  if (token_method == "lemm") {
    ### Download wordnet library
    mem_download_wordnet()

    ### Execute lemmatization
    tokens_norm <- unname(lemmatize(tokens))

  } else if (token_method == "stem"){

    ### Execute stemming
    tokens_norm <- unname(stem(tokens))

    } else {
    warning("Incorrect token normalization tag enterted.")
  }

  ### Convert to data frame
  tokens_norm.df <- data.frame(tokens_norm)

  ### Replace normalized tokens and convert tokens to sentences as vector
  model_input.v <- model_input.df %>%
    dplyr::bind_cols(tokens_norm.df) %>%
    dplyr::group_by(row_id) %>%
    dplyr::mutate(
      sentence = stringr::str_c(
        tokens_norm,
        collapse = " ")
    ) %>%
    dplyr::select(-word, -tokens_norm) %>%
    dplyr::distinct() %>%
    dplyr::pull(sentence)

  model_input.v
}


#' Remove classification predictions if both entity nodes are not
#' detected
#'
#' Removes the causality classification prediction if both Cause
#' and Effect entities are not detected.
#'
#' @param CausalityExtractionTable Output of [CausalityExtraction()]
#'
#' @noRd
#

remove_pred <- function(CausalityExtractionTable) {
  cause <- causal_relationship <- direction <- effect <- NULL

  # Manually assign which predictions to drop based on model pre-processing.
  direction_remove = FALSE
  causality_remove = TRUE

  if (causality_remove) {

    CausalityExtractionTable <- CausalityExtractionTable %>%
      dplyr::mutate(
        causal_relationship = dplyr::if_else(
          condition = ((cause == "") | (effect == "")),
          true      = "",
          false     = as.character(causal_relationship)
        )
      )

  }

  if (direction_remove) {

    CausalityExtractionTable <- CausalityExtractionTable %>%
      dplyr::mutate(
        causal_relationship = dplyr::if_else(
          condition = ((cause == "") | (effect == "")),
          true      = "",
          false     = as.character(direction)
        )
      )

  }

  # Return
  CausalityExtractionTable

}
