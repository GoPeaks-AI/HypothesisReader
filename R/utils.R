#' Generate regex expression from string
#'
#' @param input_string text to be converted to regex expression
#' @param match flag indicating if conversion should look for exact or partial
#'  match of regex expression
#' @noRd

gen_regex <- function(input_string, match){
  # Initialize
  input_string_exact <- c()

  if (match == "exact"){
    for (item in input_string){
      item_exact <- paste0("^",item,"$")
      input_string_exact <- append(input_string_exact, item_exact)

    }
    # Reassign input variable
    input_string <- input_string_exact

  }
  regex_string <- paste0("\\b(", paste(input_string, collapse="|"), ")\\b")

  regex_string
}


#' Verify input is not null
#'
#' Returns a boolean verifying is the provided input is not null
#'
#' @param x input
#' @noRd

is.not.null <- function(x) !is.null(x)
