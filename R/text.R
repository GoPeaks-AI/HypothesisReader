# REGEX Strings ----------------------------------------------------------------
## Identify Letters
regex_letters <- "[a-zA-Z]"

## Identify IP Address
regex_ip <- "(?:[\\d]{1,3})\\.(?:[\\d]{1,3})\\.(?:[\\d]{1,3})\\.(?:[\\d]{1,3})"

## Identify Parenthesis
regex_parens <- "\\(([^()]+)\\)"

## Identify Hypothesis/Proposition Formats
regex_hp_standardize <- stringr::regex("
  \\(?                                  # Open parens, optional
  \\b                                   # Word boundary
  (h|p|hypothesis\\s*|proposition\\s*)  # Acceptable label format
  [1-9][0-9]{0,2}                       # Number, one to three digits, not zero
  [a-zA-Z]?                             # Letter, optional
  \\)?                                  # Close parens, optional
  \\s*                                  # Space(s), optional
  [:,.;]?                               # Closing punctuation, optional
  \\s*                                  # Space(s), optional
  ",
                                       ignore_case = TRUE,
                                       comments = TRUE
)

## Identify hypothesis/proposition without number/label
regex_hypothesis_no_num <- "^(Hypothesis|Proposition)\\s*:"

## Single Hypothesis Tag
regex_single_tag <- "<split>hypo (.*?):"

## Duplicate Hypothesis Tag
regex_double_tag <- paste(
  regex_single_tag,
  "\\s*",
  regex_single_tag,
  sep = ""
)

## Identify Numbers
regex_return_num <- "(\\d)+"

# Functions --------------------------------------------------------------------
#' Convert PDF to text
#'
#' Converts PDF files to text using Tika.
#'
#' @param pdf_paths Vector of file paths to input pdfs
#'
#' @noRd

pdf_to_text <- function(pdf_paths) {
  text_raw <- NULL

  message("Batch PDF conversion to text: Start")

  text_raw <- rtika::tika_text(input = pdf_paths)

  message("Batch PDF conversion to text: Complete")

  # Return
  text_raw
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
#'   [input.str] should be the regex. If "inverse" is provided as flag, the
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
      input.str = remove_string,
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
#' @param input.str input string of text
#' @noRd

reduce_to_id <- Vectorize(USE.NAMES = FALSE, FUN =
  function(input.str) {
    # Set to lower case
    processed_string <- tolower(input.str)

    # Drop unnecessary text
    processed_string <- processed_string %>%
      stringr::str_remove_all(
        pattern = " ") %>%
      stringr::str_remove_all(
        pattern = "hypothesis") %>%
      stringr::str_remove_all(
        pattern = "proposition") %>%
      stringr::str_remove_all(
        pattern = stringr::regex(
          pattern = "[:punct:]"
          )
        )

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
#' variety of formats and returns a standardized tag.
#'
#' @param input.str input string of text
#' @noRd

standardize_hypothesis_proposition <- Vectorize(USE.NAMES = FALSE, FUN =
  function(input.str){

    # Count how many hypothesis/propositions are in string
    h_count <- stringr::str_count(
      string  = input.str,
      pattern = regex_hp_standardize
    )

    # Extract each hypothesis/proposition instance, all accepted formats
    if (h_count > 1) {
      extract_hp <- stringr::str_extract_all(
        string  = input.str,
        pattern = regex_hp_standardize
      )

      extract_hp <- extract_hp %>% unlist()

    } else {
      extract_hp <- stringr::str_extract(
        string  = input.str,
        pattern = regex_hp_standardize
      )
    }

    # Remove whitespace
    extract_hp <- stringr::str_trim(string = extract_hp)

    ## Add escape characters to parens and period
    extract_hp <- extract_hp %>%
      stringr::str_replace_all(
        pattern = "\\(",
        replacement = "[(]"
      ) %>%
      stringr::str_replace_all(
        pattern = "\\)",
        replacement = "[)]"
      ) %>%
      stringr::str_replace_all(
        pattern = "\\.",
        replacement = "[.]"
      )

    # Initialize output string
    output_string <- input.str

    # Check if hypothesis detected
    if (!is.na(extract_hp[1])){

      # Iterate through all hypothesis/proposition instances
      for (extract_phrase in extract_hp) {

        # Extract hypothesis number/label
        extract_number <- reduce_to_id(extract_phrase)

        # Create standardized replacement string
        standardized_string <- paste0("<split>hypo ", extract_number, ": ")

        # Replace hypothesis with new value
        output_string <- stringr::str_replace(
          string      = output_string,
          pattern     = extract_phrase,
          replacement = standardized_string
        )
        }
      }

    # Return value
    output_string

  }
)


#' Standardize hypothesis/proposition format when the hypothesis/proposition is
#'  not numbered/labeled
#'
#' The following function searches for a hypothesis or proposition without a
#' number/label and returns a hypothesis tag in the standardized form.
#'
#' @param input_vector input vector of text
#' @noRd


standardize_hypothesis_proposition_no_num <- function(input_vector) {

  # Initialize
  output_vector <- vector(
    mode   = "character",
    length = length(input_vector))

  j = 1

  # Search for hypothesis in correct format
  for (i in seq_along(input_vector)) {

    input.str <- input_vector[i]

    # Test if hypothesis format is in string
    detect_hypothesis <- stringr::str_detect(
      string = input.str,
      pattern = regex_hypothesis_no_num
    )

    # If hypothesis is detected, replace with standardized format
    if (detect_hypothesis) {

      standardized_string <- paste0("<split>hypo ", j, ": ")

      output_string <- stringr::str_replace(
        string      = input.str,
        pattern     = regex_hypothesis_no_num,
        replacement = standardized_string
      )

      output_vector[i] <- output_string
      j = j + 1

    } else {
      output_vector[i] <- input.str
    }
  }

  output_vector
}



#' Remove duplicate hypothesis/proposition standardized tags
#'
#' Removes duplicate hypothesis/proposition standardized tags where there are
#' two tags directly next to each other.
#'
#' @param input.str input string of text
#' @noRd

remove_duplicate_tag <- Vectorize(USE.NAMES = FALSE, FUN =
  function(input.str){

    # Drop whitespace
    input.str <- stringr::str_squish(input.str)

    # Extract double tag
    extract_double_tag <- stringr::str_extract(
      string  = input.str,
      pattern = regex_double_tag
    )

    # Execute if double tag detected
    if (!is.na(extract_double_tag)){

      # Extract single tag
      extract_single_tag <- stringr::str_extract_all(
        string  = extract_double_tag,
        pattern = regex_single_tag
      )

      extract_single_tag <- extract_single_tag %>% unlist()

      # Extract tag number/labels
      extract_tag_labels <- extract_single_tag %>%
        stringr::str_remove_all(
          pattern = "<split>hypo "
          ) %>%
        stringr::str_remove_all(
          pattern = ":"
          )

      # Determine number of unique labels/tags
      n_unique_labels <- length(unique(extract_tag_labels))

      ## If both labels are the same, remove one
      if (n_unique_labels == 1) {

        output.str <- input.str %>%
          stringr::str_replace_all(
            pattern     = extract_double_tag,
            replacement = extract_single_tag[1]
          )

      } else {

        output.str <- input.str

      }
    } else {

      output.str <- input.str

    }

    output.str
  }
)

#' Remove periods directly after standard hypothesis format
#'
#' In cases where there is a period (or space then period) directly after the
#' standardized hypothesis format, the sentence tokenization will split the
#' hypothesis tag from the hypothesis content. This function identifies those
#' cases and removes the period.
#'
#' @param input.str input string of text
#' @noRd

remove_period <- Vectorize(USE.NAMES = FALSE, FUN =
  function(input.str){

    # Regex identifies hypothesis with trailing period
    regex_hypo_marker_w_period <- "<split>hypo (.*?):\\s*\\."

    # Extract identified value
    extract_phrase <- stringr::str_extract(
      string  = input.str,
      pattern = regex_hypo_marker_w_period
    )

    # Check if hypothesis wither trailing period is detected
    if (!is.na(extract_phrase)){

      # Remove trailing period
      output_string <- stringr::str_replace(
        string      = input.str,
        pattern     = ":\\s*\\.",
        replacement = ": "
      )

    } else {
      output_string <- input.str

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


#' Remove periods of common abbreviations
#'
#' To avoid issues caused by greedy sentence tokenization, the periods of
#' common abbreviations are removed
#'
#' @param input_vector input string of text
#' @noRd

remove_period_abbr <- function(input_vector){

  # Define common abbreviations
  common_abbr <- c(
    "e[.]g[.]",
    "et al[.]",
    "i[.]e[.]",
    "etc[.]",
    "ibid[.]",
    " Ph[.]D[.]",
    " Q[.]E[.]D[.]",
    " q[.]e[.]d[.]"
  )

  output_vector <- input_vector

  for (abbr in common_abbr) {
    abbr_wo_period <- abbr %>%
      stringr::str_remove_all(pattern = "\\[") %>%
      stringr::str_remove_all(pattern = "\\.") %>%
      stringr::str_remove_all(pattern = "\\]")

    output_vector <- stringr::str_replace_all(
      string      = output_vector,
      pattern     = abbr,
      replacement = abbr_wo_period
    )
  }

  output_vector

  }

#' Replace/Remove common issues
#'
#' Certain words/phrases have resulted in errors in hypothesis/proposition
#' extraction. To avoid such errors, this function modifies these words/
#' phrases so that they avoid being caught in the hypothesis/proposition
#' identification steps.
#'
#' @param input_vector input string of text
#' @noRd


fix_common_error_traps <- function(input_vector){

  # S&P Index
  ## Modified to identify any number

  regex_sp <- "(S&P)(\\s*)([0-9]{1,5})"
  regex_sp <- stringr::regex(regex_sp, ignore_case = TRUE)

  # Add underscore between s&p and index number
  output_vector <- stringr::str_replace_all(
    string = input_vector,
    pattern = regex_sp,
    replacement = {

      index_num <- stringr::str_extract(
        string  = input_vector,
        pattern = "(\\d)+")

      paste("s&p_", index_num, sep = "")

    }
  )
    output_vector
}


#' Detect if text extraction of PDF failed.
#'
#' Examines all text from PDFs returns index of PDF which did not convert to
#' text.
#'
#' @param input_text Converted text of all input PDF documents
#' @noRd

text_conversion_test <- function(input_text) {
  rmv_newline <- NULL

  # Remove newlines symbols
  text_newline_removed = gsub(
    pattern = "\n",
    replacement = "",
    x = input_text
  )

  # Determine index of files with no text after newline removal
  idx_failed_conversion <- c()
  for (i in seq_along(text_newline_removed)) {

    if (nchar(text_newline_removed[i]) < 1) {
      idx_failed_conversion <- c(idx_failed_conversion, i)
    }
  }

  # Return
  idx_failed_conversion

}

#' Process PDF text
#'
#' Wrapper function. Executes all steps in the process flow converting raw
#' PDF file into text. This processing step returns text that will be used as
#' input for the major functions in the package:
#' * Hypothesis classification
#' * Entity extraction
#' * Causality classification
#' * Direction classification
#'
#' @param text_raw Raw PDF converted text
#' @noRd

process_text <- function(text_raw){
  pdf_to_text <- NULL

  # Vectorize ------------------------------------------------------------------
  ## Split text into character vector
  text_processed <- text_raw %>%
    stringr::str_split(pattern = "\n") %>%
    unlist()

  # White -space ---------------------------------------------------------------
  # Trim excess - outside and inside strings
  text_processed <- stringr::str_trim(string = text_processed)
  text_processed <- stringr::str_squish(string = text_processed)

  # References / Bibliography --------------------------------------------------
  ## Remove any text in DF document which occurs after the Reference/
  ## Bibliography, if one exists.
  ### Return Logical Vector
  logical_section <- ifelse(
    test = (
      tolower(text_processed) == "references" |
      tolower(text_processed) == "bibliography"
    ),
    yes  = TRUE,
    no   = FALSE)

  ### Drop elements After first instance of Reference or Bibliography is
  ### identified.
  if (any(logical_section)){
    index <- min(which(logical_section == TRUE))
    text_processed <- text_processed[1:index-1]
  }

  # Numbers and Symbols --------------------------------------------------------
  ## Drop lines with only numbers or symbols
  text_processed <- remove_if_detect(
    input_vector   = text_processed,
    regex          = regex_letters,
    logical_method = "inverse"
  )

  # n < 1 ----------------------------------------------------------------------
  ## Drop elements with length of 1 or less
  logical_length <- nchar(text_processed) > 1
  text_processed <- text_processed[logical_length]

  # Drop any NA elements
  text_processed <- text_processed[!is.na(text_processed)]

  # Months ---------------------------------------------------------------------
  ## Remove elements which start with a month
  text_processed <- remove_if_detect(
    input_vector  = text_processed,
    remove_string = toupper(month.name),
    location      = "start"
  )

  ## Drop any NA elements
  text_processed <- text_processed[!is.na(text_processed)]

  # Hyphen Concatenation -------------------------------------------------------
  ## Concatenate adjacent elements if initial element ends With hyphen
  text_processed <- concat_hypen_vector(text_processed)

  # Downloading ----------------------------------------------------------------
  ## Remove elements which contain text related to downloading documents.

  download_vec <- c('This content downloaded','http','jsto','DOI','doi')

  text_processed <- remove_if_detect(
    input_vector  = text_processed,
    remove_string = download_vec,
    location      = "any"
  )

  # IP Address -----------------------------------------------------------------
  ## Remove elements which contain IP addresses

  text_processed <- remove_if_detect(
    input_vector = text_processed,
    regex        = regex_ip,
    location     = "any"
  )

  # # Parenthesis ----------------------------------------------------------------
  # ## Remove text within parenthesis
  # ### Define term to identify line splits
  # line_split_indicator <- " -LINESPLIT-"
  #
  # ### Concatenate all vector elements, separated by line split
  # text_processed <- stringr::str_c(
  #   text_processed,
  #   collapse = line_split_indicator
  # )
  #
  # # Remove content within parenthesis
  # text_processed <- stringr::str_remove_all(
  #   string  = text_processed,
  #   pattern = regex_parens
  # )
  #
  # # Split single string back into character vectors
  # text_processed <- stringr::str_split(
  #   string  = text_processed,
  #   pattern = line_split_indicator) %>%
  #   unlist()

  # Empty Vectors --------------------------------------------------------------
  ## Drop empty vectors
  text_processed <- text_processed[text_processed!=""]

  ## Drop NA elements
  text_processed <- text_processed[!is.na(text_processed)]

  # Numbers and Symbols (Second Time) ------------------------------------------
  ## Drop lines with only numbers or symbols
  text_processed <- remove_if_detect(
    input_vector   = text_processed,
    regex          = regex_letters,
    logical_method = "inverse"
  )

  # Common Issues --------------------------------------------------------------
  ## Remove Periods From Common Abbreviations
  text_processed <- remove_period_abbr(text_processed)

  ## Adjust common error traps
  text_processed <- fix_common_error_traps(text_processed)

  # Standardize Hypothesis/Propositions-----------------------------------------
  ## Hypothesis
  text_processed <- standardize_hypothesis_proposition(
    input.str  = text_processed
  )

  ## Test if any hypothesis standardized
  n_hypothesis_test <- sum(
    stringr::str_count(
      string = text_processed,
      pattern = "<split>hypo"
      )
    )

  ## If no hypothesis detected, attempt to standardize hypothesis/proposition
  ## formats without number/labels
  if (n_hypothesis_test == 0) {
    text_processed <- standardize_hypothesis_proposition_no_num(
      input_vector  = text_processed
    )
  }

  ## Remove Duplicate Tags
  text_processed <- remove_duplicate_tag(
    input.str = text_processed
  )

  # Remove trailing period for standardizes hypothesis tags
  text_processed <- remove_period(
    input.str = text_processed
  )

  # Tokenize Sentences ---------------------------------------------------------
  ## Pass 1 - Tokenizers
  text_processed <- stringr::str_c(
    text_processed,
    collapse = " "
  )

  text_processed <- tokenizers::tokenize_sentences(
    text_processed,
    strip_punct = FALSE) %>%
    unlist()

  ## Pass 2 - Stringr
  ### Instances of sentences not being correctly tokenized have been seen
  ### using the Tokenizer method. This additional sentence tokenization step
  ### has been added to compensate
  text_processed <- stringr::str_split(
    string  = text_processed,
    pattern = "\\.") %>%
    unlist()

  ## Drop empty vectors
  text_processed <- text_processed[text_processed!=""]


  ## Replace double spaces with single
  text_processed <- stringr::str_replace_all(
    string      = text_processed,
    pattern     = "  ",
    replacement = " "
  )

  # Normalize Case -------------------------------------------------------------
  ## Set everything to lowercase
  text_processed <- tolower(text_processed)

  # Downloading (Second Time) --------------------------------------------------
  ## Remove elements which contain terms related to downloading files
  text_processed <- remove_if_detect(
    input_vector  = text_processed,
    remove_string = download_vec,
    location      = "any"
  )

  # Numbers and Symbols (Third Time) -------------------------------------------
  ## Drop lines with only numbers or symbols
  text_processed <- remove_if_detect(
    input_vector   = text_processed,
    regex          = regex_letters,
    logical_method = "inverse"
  )

  # Break out sentences with multiple hypothesis tags --------------------------
  text_processed = break_out_hypothesis_tags(input.v = text_processed)

  # Misc Text Actions ----------------------------------------------------------
  ## Replace double colons
  text_processed <- stringr::str_replace_all(
    string      = text_processed,
    pattern     = ": :",
    replacement = ":"
  )

  ## Remove extra white space
  text_processed <- stringr::str_squish(
    string = text_processed
  )

  ## Replace colon/period instances (: .)
  text_processed <- stringr::str_replace_all(
    string      = text_processed,
    pattern     = ": \\.",
    replacement = ":"
  )

  text_processed
}
