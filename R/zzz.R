# Initialize as null
joblib <- nltk <- nltk_stem <- np <- tf <- NULL

.onLoad <- function(libname, pkgname) {
  # Set TensorFlow environmental variable to quiet output on start-up
  Sys.setenv(TF_CPP_MIN_LOG_LEVEL = 3)

  # Load Python Modules
  # use super-assignment to update global reference
  joblib    <<- reticulate::import("joblib",                delay_load = TRUE)
  nltk      <<- reticulate::import("nltk",                  delay_load = TRUE)
  nltk_stem <<- reticulate::import("nltk.stem",             delay_load = TRUE)
  np        <<- reticulate::import("numpy",                 delay_load = TRUE)
  tf        <<- reticulate::import("tensorflow",            delay_load = TRUE)


  # Allows user to load additional modules
  reticulate::configure_environment(pkgname)

  # Install Tika Jar
  #TBD Check if already installed
  jar <- rtika::tika_jar()

  if (is.na(jar)) {
    rtika::install_tika()
  }
}
