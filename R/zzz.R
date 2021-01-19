# np <- NULL
# tf <- NULL
# joblib <- NULL
# nltk_stem <- NULL
#
# .onLoad <- function(libname, pkgname) {
#   # use superassignment to update global reference
#   np <<- reticulate::import("numpy", delay_load = TRUE)
#   tf <<- reticulate::import("tensorflow", delay_load = TRUE)
#   joblib    <<- reticulate::import("joblib", delay_load = TRUE)
#   nltk_stem <<- reticulate::import("nltk.stem", delay_load = TRUE)
#   model_causality <- joblib$load(get_path_causality_model())
# }

nltk <- NULL
.onLoad <- function(libname, pkgname) {
  reticulate::configure_environment(pkgname)

  nltk <<- reticulate::import("nltk", delay_load = TRUE)
  nltk$download("wordnet")
}
