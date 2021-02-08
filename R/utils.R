#' Generate regex expression from string
#'
#' @param input.str text to be converted to regex expression
#' @param match flag indicating if conversion should look for exact or partial
#'  match of regex expression
#' @noRd

gen_regex <- function(input.str, match){
  # Initialize
  input.str_exact <- c()

  if (match == "exact"){
    for (item in input.str){
      item_exact <- paste0("^",item,"$")
      input.str_exact <- append(input.str_exact, item_exact)

    }
    # Reassign input variable
    input.str <- input.str_exact

  }
  regex_string <- paste0("\\b(", paste(input.str, collapse="|"), ")\\b")

  regex_string
}


#' Verify input is not null
#'
#' Returns a boolean verifying is the provided input is not null
#'
#' @param x input
#' @noRd

is.not.null <- function(x) !is.null(x)
