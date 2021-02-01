# REGEX Strings ----------------------------------------------------------------
## Identify Letters
regex_letters <- "[a-zA-Z]"

## Identify IP Address
regex_ip <- "(?:[\\d]{1,3})\\.(?:[\\d]{1,3})\\.(?:[\\d]{1,3})\\.(?:[\\d]{1,3})"

## Identify Parenthesis
regex_parens <- "\\(([^()]+)\\)"

## Identify Hypothesis/Proposition Formats
regex_standardize <- paste(
  "(h|p|hypothesis|proposition)(\\s*)",
  "([0-9]{1,3}[a-zA-Z]|[0-9]{1,3})(\\s*)(\\:|\\.)?",
  sep = ""
)

## Identify Numbers
regex_return_num <- "(\\d)+"

# Functions --------------------------------------------------------------------
#' Retrieve path to python script
#'
#' Retrieves the path to python script for converting PDF files to text.
#'
#' @noRd

get_path_pdf2text <- function() {
  system.file("python", "pdf_to_text.py",
              package = 'CausalityExtraction')
}


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


#' Reduce hypothesis/proposition to id
#'
#' The following function reduces a hypothesis or proposition label to its
#' number/id
#'
#' @param input_string input string of text
#' @noRd
#'

reduce_to_id <- Vectorize(
  function(input_string) {

    # Drop unnecessary text
    processed_string <- input_string %>%
      stringr::str_remove_all(
        pattern = " ") %>%
      stringr::str_remove_all(
        pattern = "hypothesis") %>%
      stringr::str_remove_all(
        pattern = "proposition") %>%
      stringr::str_remove_all(
        pattern = ":") %>%
      stringr::str_remove_all(
        pattern = "\\.")

    # Remove leading h if present
    processed_string <- ifelse(
      test = substr(
        x     = processed_string,
        start = 1,
        stop  = 1) == "h",
      yes = substr(
        x     = processed_string,
        start = 2,
        stop  = nchar(processed_string)
      ),
      no = processed_string
      )

    # Remove leading p if present
    output_string_string <- ifelse(
      test = substr(
        x     = processed_string,
        start = 1,
        stop  = 1) == "p",
      yes = substr(
        x     = processed_string,
        start = 2,
        stop  = nchar(processed_string)
      ),
      no = processed_string
    )

    output_string_string
  }
)


#' Standardize hypothesis/proposition format
#'
#' The following function searches for a hypothesis or proposition in a
#' variety of formats.
#'
#' @param input_string input string of text
#' @noRd

standardize_hypothesis_proposition <- Vectorize(
  function(input_string){

    # Extract identified value
    extract_phrase <- stringr::str_extract(
      string  = input_string,
      pattern = regex_standardize
    )

    # Check if hypothesis detected
    if (!is.na(extract_phrase)){

      # Extract hypothesis number
      extract_number <- reduce_to_id(extract_phrase)

      # Create new string
      standardized_string <- paste0("<split>hypo ", extract_number, ": ")

      # Replace hypothesis with new value
      output_string <- stringr::str_replace(
        string      = input_string,
        pattern     = extract_phrase,
        replacement = standardized_string
      )

    } else {
      output_string <- input_string

    }

    output_string

  }
)


#' Remove periods directly after standard hypothesis format
#'
#' In cases where there is a period (or space then period) directly after the
#' standardized hypothesis format, the sentence tokenization will split the
#' hypothesis tag from the hypothesis content. This function identifies those
#' cases and removes the period.
#'
#' @param input_string input string of text
#' @noRd

remove_period <- Vectorize(
  function(input_string){

    # Regex identifies hypothesis with trailing period
    regex_hypo_marker_w_period <- "<split>hypo (.*?):\\s?."

    # Extract identified value
    extract_phrase <- stringr::str_extract(
      string  = input_string,
      pattern = regex_hypo_marker_w_period
    )

    # Check if hypothesis wither trailing period is detected
    if (!is.na(extract_phrase)){

      # Remove trailing period
      output_string <- stringr::str_replace(
        string      = input_string,
        pattern     = ":\\s?.",
        replacement = ":"
      )

    } else {
      output_string <- input_string

    }

    output_string

  }
)


#' Break out sentences with multiple standardized hypothesis tags
#'
#' In cases where there are multiple standardized hypothesis tags, hypothesis
#' identification can be compromised, as the downstream process only acts on
#' the first instance of a hypothesis tag. Therefore, the following function
#' splits any sentence with multiple standardized hypothesis tags, ensuring
#' one tag max per sentence
#'
#' @param input.v vector of processed text sentences
#' @noRd
#

break_out_hypothesis_tags <- function(input.v) {

  n_output_sentences <- output.list <- output.v <- split_index <- NULL
  start <- temp.v <- NULL

  # Initialize
  output.list <- vector(mode = "list", length = length(input.v))
  regex_hypo_marker <- "<split>hypo (.*?):"

  # Iterate through all input sentences
  for (i in seq_along(input.v)) {
    sentence <- input.v[i]

    # Locate all instances of hypothesis tags
    hypo_locate <- stringr::str_locate_all(
      string  = sentence,
      pattern = regex_hypo_marker
    )

    # Convert to dataframe
    hypo_locate.df <- as.data.frame(hypo_locate[[1]])

    # Extract split index vector
    split_index <- hypo_locate.df %>% dplyr::pull(start)

    # If hypothesis tag is not identified, no action
    if (purrr::is_empty(split_index)) {

      output.list[[i]] <- sentence

    } else {
      # Add start and stop string indexes
      split_index <- c(1, split_index, nchar(sentence) + 1)

      # Determine number of sentence splits
      n_output_sentences <- length(split_index) - 1

      # Initialize
      j <- 1
      temp.v <- vector(mode = "character", length = n_output_sentences)

      # Split input sentence into separate parts
      while (j <= n_output_sentences) {
        # Extract sentence fragment
        sentence_split <- stringr::str_sub(
          string = sentence,
          start  = split_index[j],
          end    = split_index[j+1] - 1
        )

        # Save extract to temporary vector
        temp.v[j] = sentence_split

        j <- j + 1

        }
      # save temporary vector to output list
      output.list[[i]] <- temp.v
      }
  }
  # Convert output list to vector
  output.v <- unlist(output.list, use.names = FALSE)
  output.v
}


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
  pdf_to_text <- NULL
  # Convert --------------------------------------------------------------------

  ## Use PDFminer.six high level function
  input_text <- pdfminer$extract_text(input_path)


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

  ### Drop elements After first instance of Reference or Bibliography is
  ### identified.
  if (any(logical_section)){
    index <- min(which(logical_section == TRUE))
    processing_text <- processing_text[1:index-1]
  }

  # Normalize Case -------------------------------------------------------------
  ## Set everything to lowercase
  processing_text <- tolower(processing_text)

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

  # # Parenthesis ----------------------------------------------------------------
  # ## Remove text within parenthesis
  # ### Define term to identify line splits
  # line_split_indicator <- " -LINESPLIT-"
  #
  # ### Concatenate all vector elements, separated by line split
  # processing_text <- stringr::str_c(
  #   processing_text,
  #   collapse = line_split_indicator
  # )
  #
  # # Remove content within parenthesis
  # processing_text <- stringr::str_remove_all(
  #   string  = processing_text,
  #   pattern = regex_parens
  # )
  #
  # # Split single string back into character vectors
  # processing_text <- stringr::str_split(
  #   string  = processing_text,
  #   pattern = line_split_indicator) %>%
  #   unlist()

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

  # Standardize Hypothesis/Propositions-----------------------------------------
  ## Hypothesis
  processing_text <- standardize_hypothesis_proposition(
    input_string  = processing_text
  )

  # Remove trailing period for standardizes hypothesis tags
  processing_text <- remove_period(
    input_string = processing_text
  )

  ## Drop object names
  processing_text <- unname(processing_text)


  # Tokenize Sentences ---------------------------------------------------------
  ## Pass 1 - Tokenizers
  processing_text <- stringr::str_c(
    processing_text,
    collapse = " "
  )

  processing_text <- tokenizers::tokenize_sentences(
    processing_text,
    strip_punct = FALSE) %>%
    unlist()

  ## Pass 2 - Stringr
  ### Instances of sentences not being correctly tokenized have been seen
  ### using the Tokenizer method. This additional sentence tokenization step
  ### has been added to compensate
  processing_text <- stringr::str_split(
    string  = processing_text,
    pattern = "\\.") %>%
    unlist()

  ## Drop empty vectors
  processing_text <- processing_text[processing_text!=""]


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

  # Break out sentences with multiple hypothesis tags --------------------------
  processing_text = break_out_hypothesis_tags(input.v = processing_text)

  # Misc Text Actions ----------------------------------------------------------
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
