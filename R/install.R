#' Causality extraction process
#'
#' Executes the complete causality extraction process.
#'
#' @param method Installation method. By default, "auto" automatically finds a
#' method that will work in the local environment. Change the default to force
#' a specific installation method. Note that the "virtualenv" method is not
#' available on Windows.
#'
#' @param conda The path to a conda executable. Use "auto" to allow reticulate
#' to automatically find an appropriate conda binary. See Finding Conda for
#' more details.
#'
#' @export

install_CausalityExtraction <- function(method = "auto", conda = "auto") {
  reticulate::py_install("joblib==1.0.0", method = method,
                         conda = conda, pip = TRUE)

  reticulate::py_install("nltk==3.5", method = method,
                         conda = conda, pip = TRUE)

  reticulate::py_install("numpy", method = method,
                         conda = conda, pip = TRUE)

  reticulate::py_install("pdfminer.six==20201018", method = method,
                         conda = conda, pip = TRUE)

  reticulate::py_install("scikit-learn==0.23.2", method = method,
                         conda = conda, pip = TRUE)

  reticulate::py_install("tensorflow==2.4.0", method = method,
                         conda = conda, pip = TRUE)


}
