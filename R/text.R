# REGEX Strings ----------------------------------------------------------------
## Identify Letters
regex_letters <- "[a-zA-Z]"

## Identify IP Address
regex_ip <- "(?:[\\d]{1,3})\\.(?:[\\d]{1,3})\\.(?:[\\d]{1,3})\\.(?:[\\d]{1,3})"

## Identify Parenthesis
regex_parens <- "\\(([^()]+)\\)"

## Identify Hypothesis Formats
regex_hypo <- c("h[0-9]{1,3}[a-zA-Z]\\:",
                "H[0-9]{1,3}[a-zA-Z]\\:",
                "h[0-9]{1,3}[a-zA-Z]\\.",
                "H[0-9]{1,3}[a-zA-Z]\\.",
                "h[0-9]{1,3}[a-zA-Z]",
                "H[0-9]{1,3}[a-zA-Z]",
                "hypothesis [0-9]{1,3}[a-zA-Z]\\:",
                "Hypothesis [0-9]{1,3}[a-zA-Z]\\:",
                "hypothesis [0-9]{1,3}[a-zA-Z]\\.",
                "Hypothesis [0-9]{1,3}[a-zA-Z]\\.",
                "hypothesis [0-9]{1,3}[a-zA-Z]",
                "Hypothesis [0-9]{1,3}[a-zA-Z]",
                "h[0-9]{1,3}\\:",
                "H[0-9]{1,3}\\:",
                "h[0-9]{1,3}\\.",
                "H[0-9]{1,3}\\.",
                "h[0-9]{1,3}",
                "H[0-9]{1,3}",
                "hypothesis [0-9]{1,3}\\:",
                "Hypothesis [0-9]{1,3}\\:",
                "hypothesis [0-9]{1,3}\\.",
                "Hypothesis [0-9]{1,3}\\.",
                "hypothesis [0-9]{1,3}",
                "Hypothesis [0-9]{1,3}")

## Identify Numbers
regex_return_num <- "(\\d)+"

# Functions -------------------------------------------------------------------
#' Remove string by regex expression
#'
#' Removes a string if it matches to the provided Regular Expression (regex). If a regex
#' is not provided, a character string may be provided and converted into a
#' regex which will then be used to identify any of the text in the
#' input string.
#'
#' @param input_vector text to be tested by regex
#' @param regex Regex input
#' @param remove_string String to be converted into regex if [regex] is not
#'  provided
#' @param location text indicating if removal will be based on "start", "end",
#'  or "any" location in the [input_vector]
#'  @param match Flag indicating if a match should be "exact" or "partial.
#'   Defaults to "partial".
#'  @param logical_method Flag indicating if the text removed from the
#'   [input_string] should be the regex. If "inverse" is provided as flag, the
#'   text removed will be everything BUT the regex.
#'
#' @noRd

remove_if_detect <- function(input_vector,
                             regex = NULL,
                             remove_string = NULL,
                             location = "any",
                             match = "partial",
                             logical_method = "direct"){

  # Generate regex input based on string if regex is not provided
  if (is.null(regex)){
    regex <- gen_regex(
      input_string = remove_string,
      match        = match)
  }

  logical_vector = c()
  if (location == "start"){
    # Check Start of String
    logical_vector <- stringr::str_starts(
      string  = input_vector,
      pattern = regex
    )

  } else if ( location == "end") {
    # Check End of String
    logical_vector <- stringr::str_ends(
      string  = input_vector,
      pattern = regex
    )

  } else {
    logical_vector <- stringr::str_detect(
      string = input_vector,
      pattern = regex
    )
  }


  # Drop elements NOT identified in the logical vector. If inverse method
  # is selected, elements that ARE identified are dropped.

  if (logical_method == "inverse") {
    output_vector <- input_vector[logical_vector]

  } else {
    output_vector <- input_vector[!logical_vector]
  }


  # Drop any NA values
  output_vector <- output_vector[!is.na(output_vector)]

  output_vector
}

#' Concatenate two strings while dropping connecting hyphen
#'
#' Concatenates two strings together and removes the hyphen separating them.
#'
#' @param string_1 string, first observed in the source text
#' @param string_2 string, second observed in the source text
#' @noRd

concat_hyphen_string <- function(string_1, string_2){
  # Remove tail hyphen
  string_1 <- stringr::str_sub(
    string = string_1,
    start  = 1,
    end    = nchar(string_1) - 1
  )

  # Concatenate strings
  output <- stringr::str_c(string_1, string_2)

  output
}

#' Execute [concat_hyphen_string()] across vector
#'
#' Executes [concat_hyphen_string()] across a character vector.
#' @param input_vector character vector
#' @noRd

concat_hypen_vector <- function(input_vector){
  # Initialize
  i <- 1
  j <- 1
  output_vector = c()

  while (i <= length(input_vector)){
    item = input_vector[i]

    # Test if element Ends in hyphen
    hyphen_test <- stringr::str_ends(
      string  = item,
      pattern = "-"
    )

    # Execute if test = TRUE
    while (hyphen_test){
      # Concatenate element i with element i+1
      item <- concat_hyphen_string(item, input_vector[i+j])

      # Test if new element ends in hyphen
      hyphen_test <- stringr::str_ends(
        string  = item,
        pattern = "-"
      )

      j = j + 1
    }
    output_vector <- append(output_vector, item)
    i = i + j
    j = 1
  }
  output_vector
}

#' Standardize hypothesis format
#'
#' The following function searches for a hypothesis in each character vector
#' element. Hypotheses of different formats are identified based on a
#' provided vector of regex strings. All identified hypotheses are converted to
#' a standard format.
#'
#' @param input_string input string of text
#' @param regex_hypothesis_string regex identifying hypothesis formats
#' @noRd

standardize_hypothesis <- Vectorize(
  function(input_string, regex_hypothesis_string){

    # Extract identified value
    extract_phrase <- stringr::str_extract(
      string  = input_string,
      pattern = regex_hypothesis_string
    )

    # Check if hypothesis detected
    if (!is.na(extract_phrase)){

      # Extract hypothesis number
      extact_number <- stringr::str_extract(
        string  = extract_phrase,
        pattern = regex_return_num
      )

      # Create new string
      replacement_string <- paste0("<split>Hypo ", extact_number, ": ")

      # Replace hypothesis with new value
      output_string <- stringr::str_replace(
        string      = input_string,
        pattern     = regex_hypothesis_string,
        replacement = replacement_string
      )

    } else {
      output_string <- input_string

    }

    output_string

  }
)



#' Process PDF text
#'
#' Wrapper function. Executes all steps in the process flow converting raw
#' PDF file into text. This processing step returns text that will be used as
#' input for the three major functions in the package:
#' * Hypothesis classification
#' * Entity extraction
#' * Causality classification
#'
#' @param input_path path to PDF file

process_text <- function(input_path){

  # Convert --------------------------------------------------------------------
  input_text <- pdf_to_text_pdfminer(input_path)

  # Vectorize ------------------------------------------------------------------
  ## Split text into character vector
  processing_text <- input_text %>%
    stringr::str_split(pattern = "\r\n") %>%
    stringr::str_split(pattern = "\n") %>%
    unlist()

  # References / Bibliography --------------------------------------------------
  ## Remove any text in DF document which occurs after the Reference/
  ## Bibliography, if one exists.
  ### Define PDF sections labels
  section_key <- c("References", "Bibliography",
                   "REFERENCES", "BIBIOGRAPHY")

  ### Convert to regex
  regex_section <- gen_regex(
    input_string = section_key,
    match        = "exact"
  )

  ### Return Logical Vector
  logical_section <- stringr::str_detect(
    string  = processing_text,
    pattern = regex_section)

  ### Drop elements After first instance of Referece or Bibliography is
  ### identified.
  if (any(logical_section)){
    index <- min(which(logical_section == TRUE))
    processing_text <- processing_text[1:index-1]
  }

  # Numbers and Symbols --------------------------------------------------------
  ## Drop lines with only numbers or symbols
  processing_text <- remove_if_detect(
    input_vector   = processing_text,
    regex          = regex_letters,
    logical_method = "inverse"
  )

  # n < 1 ----------------------------------------------------------------------
  ## Drop elements with length of 1 or less
  logical_length <- nchar(processing_text) > 1
  processing_text <- processing_text[logical_length]

  # Drop any NA elements
  processing_text <- processing_text[!is.na(processing_text)]

  # Months ---------------------------------------------------------------------
  ## Remove elements which start with a month
  processing_text <- remove_if_detect(
    input_vector  = processing_text,
    remove_string = toupper(month.name),
    location      = "start"
  )

  ## Drop any NA elements
  processing_text <- processing_text[!is.na(processing_text)]

  # Hyphen Concatenation -------------------------------------------------------
  ## Concatenate adjacent elements if initial element ends With hyphen
  processing_text <- concat_hypen_vector(processing_text)

  # Downloading ----------------------------------------------------------------
  ## Remove elements which contain text related to downloading documents.

  download_vec <- c('This content downloaded','http','jsto','DOI','doi')

  processing_text <- remove_if_detect(
    input_vector  = processing_text,
    remove_string = download_vec,
    location      = "any"
  )

  # IP Address -----------------------------------------------------------------
  ## Remove elements which contain IP addresses

  processing_text <- remove_if_detect(
    input_vector = processing_text,
    regex        = regex_ip,
    location     = "any"
  )

  # Parenthesis ----------------------------------------------------------------
  ## Remove text within parenthesis
  ### Define term to identify line splits
  line_split_indicator <- " -LINESPLIT-"

  ### Concatenate all vector elements, separated by line split
  processing_text <- stringr::str_c(
    processing_text,
    collapse = line_split_indicator
  )

  # Remove content within parenthesis
  processing_text <- stringr::str_remove_all(
    string  = processing_text,
    pattern = regex_parens
  )

  # Split single string back into character vectors
  processing_text <- stringr::str_split(
    string  = processing_text,
    pattern = line_split_indicator) %>%
    unlist()

  # Empty Vectors --------------------------------------------------------------
  ## Drop empty vectors
  processing_text <- processing_text[processing_text!=""]

  ## Drop NA elements
  processing_text <- processing_text[!is.na(processing_text)]

  # Numbers and Symbols (Second Time) ------------------------------------------
  ## Drop lines with only numbers or symbols
  processing_text <- remove_if_detect(
    input_vector   = processing_text,
    regex          = regex_letters,
    logical_method = "inverse"
  )

  # Tokenize Sentences ---------------------------------------------------------
  ## Convert Vector Elements into Sentences
  processing_text <- stringr::str_c(
    processing_text,
    collapse = " "
  )

  processing_text <- tokenizers::tokenize_sentences(
    processing_text,
    strip_punct = FALSE) %>%
    unlist()

  ## Replace double spaces with single
  processing_text <- stringr::str_replace_all(
    string      = processing_text,
    pattern     = "  ",
    replacement = " "
  )

  # Downloading (Second Time) --------------------------------------------------
  ## Remove elements which contain terms related to downloading files
  processing_text <- remove_if_detect(
    input_vector  = processing_text,
    remove_string = download_vec,
    location      = "any"
  )

  # Numbers and Symbols (Third Time) -------------------------------------------
  ## Drop lines with only numbers or symbols
  processing_text <- remove_if_detect(
    input_vector   = processing_text,
    regex          = regex_letters,
    logical_method = "inverse"
  )

  # Standardize Hypothesis -----------------------------------------------------
  ## Generate regex identify hypotheses
  regex_hypo_str <- gen_regex(
    input_string = regex_hypo,
    match        = "partial"
  )

  processing_text <- standardize_hypothesis(
    input_string            = processing_text,
    regex_hypothesis_string = regex_hypo_str
  )

  ## Drop object names
  processing_text <- unname(processing_text)

  # Misc Text Replacement ------------------------------------------------------
  ## Replace double colons
  processing_text <- stringr::str_replace_all(
    string      = processing_text,
    pattern     = ": :",
    replacement = ":"
  )

  ## Remove extra white space
  processing_text <- stringr::str_squish(
    string = processing_text
  )

  ## Replace colon/period instances (: .)
  processing_text <- stringr::str_replace_all(
    string      = processing_text,
    pattern     = ": \\.",
    replacement = ":"
  )

  processing_text
}
