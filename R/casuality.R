#' Retrieve path to causality classification model
#'
#' Retrieves the path to the causality classification model. This prevents a
#' hard path being defined, which would cause an error when verifying
#' staged installation.
#'
#' @noRd

get_path_causality_model <- function() {
  system.file("extdata", "models",
              "causality_classification.joblib",
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


#' Generate causality classification predictions
#'
#' Generates the causality classification predictions.
#'
#' @param model_input Output of [gen_causality_model_input()]
#'
#' @noRd
#

gen_causality_class <- function(model_input) {
  causality_pred <- model_causality <- NULL

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
#' The causality classification model was trained under the following
#' conditions :
#'  * Token normalization method: stemming
#'  * Cause/Effect entity replacement: yes
#'  * Imbalanced Sampling: no
#'  * Feature processing: Bag-of-words
#'  * Model: Naive Bayes - Multinomial
#'
#' @param hypothesis_df hypothesis statement output of [hypothesis_extraction()]
#'

causality_classification <- function(hypothesis_df) {
  causality <- causality_pred <- NULL

  # Process hypothesis into model input
  model_input <- gen_causality_direction_model_input(
    hypothesis_df = hypothesis_df,
    entity_extraction = TRUE,
    token_method = "stem"
    )

  # Generate causality predictions
  causality_pred <- gen_causality_class(model_input)

  causality <- data.frame(causality_pred)

  causality
}

