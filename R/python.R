get_path_pdf2text <- function() {
  system.file("python", "pdf_to_text.py",
              package = 'CausalityExtraction')
}

reticulate::source_python(get_path_pdf2text())


