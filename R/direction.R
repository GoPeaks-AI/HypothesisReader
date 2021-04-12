#' Retrieve path to direction classification model
#'
#' Retrieves the path to the direction classification model. This prevents a
#' hard path being defined, which would cause an error when verifying
#' staged installation.
#'
#' @noRd

get_path_direction_model <- function() {
  system.file("extdata", "models",
              "direction.joblib",
              package = 'HypothesisReader')
}


#' Load direction classification model
#'
#' Loads the direction classification model. Wrapped in memoise to avoid
#' repeated loading of the same model.
#'
#' @noRd

load_direction_model <- function() {
  model_direction <- NULL
  model_direction <- joblib$load(get_path_direction_model())
  model_direction
}

mem_load_direction_model <- memoise::memoise(load_direction_model)


#' Generate direction classification predictions
#'
#' Generates the direction classification predictions.
#'
#' @param model_input Output of [gen_direction_model_input()]
#'
#' @noRd
#

gen_direction_class <- function(model_input) {
  direction_pred <- model_direction <- NULL

  # Load direction model
  model_direction <- mem_load_direction_model()

  # Convert to numpy array
  model_input_np <- np$array(model_input)

  # Generate predictions
  direction_pred <- model_direction$predict(model_input_np)

  direction_pred

}


#' Direction classification
#'
#' Wrapper function. Executes all steps in the direction classification process.
#' The direction classification model was trained under the following
#' conditions :
#'  * Token normalization method: stemming
#'  * Cause/Effect entity replacement: no
#'  * Imbalanced Sampling: no
#'  * Feature processing: Bag-of-words
#'  * Model: Logistic Regression
#'
#' @param hypothesis_df hypothesis statement output of [hypothesis_extraction()]
#'
#' @noRd

direction_classification <- function(hypothesis_df) {
  direction <- direction_pred <- NULL

  # Process hypothesis into model input
  model_input <- gen_causality_direction_model_input(
    hypothesis_df = hypothesis_df,
    entity_extraction = FALSE,
    token_method = "stem"
  )

  # Generate predictions
  direction_pred <- gen_direction_class(model_input)

  direction <- data.frame(direction_pred)

  direction
}

