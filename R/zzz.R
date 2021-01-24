# Initialize as null
joblib <- nltk <- nltk_stem <- np <- pdfminer <- tf <- NULL

.onLoad <- function(libname, pkgname) {
  # Load Python Modules
  # use super-assignment to update global reference
  joblib    <<- reticulate::import("joblib",     delay_load = TRUE)
  nltk      <<- reticulate::import("nltk",       delay_load = TRUE)
  nltk_stem <<- reticulate::import("nltk.stem",  delay_load = TRUE)
  np        <<- reticulate::import("numpy",      delay_load = TRUE)
  pdfminer  <<- reticulate::import("pdfminer",   delay_load = TRUE)
  tf        <<- reticulate::import("tensorflow", delay_load = TRUE)


  # Allows user to load additional modules
  reticulate::configure_environment(pkgname)
}
