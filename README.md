# CausalityExtraction

  <!-- badges: start -->
  [![R-CMD-check](https://github.com/canfielder/CausalityExtraction/workflows/R-CMD-check/badge.svg)](https://github.com/canfielder/CausalityExtraction/actions)
  <!-- badges: end -->

The **CausalityExtraction** R package supports the analytic methods as described in <insert academic paper>. The main action of this package is to extract any and all hypothesis and/or proposition statements found in the provided documents. Once these statements are extracted, the following information regarding each statement is determined:
  
  * Entities: Extract both the cause and the effect entities within the statement
  * Causality: Classify if the hypothesis/proposition is a causal relationship
  * Direction: Classify the direction of the statement (positive, negative, non-linear)

The **CausalityExtraction** package utilizes Python and R. Therefore, a Python interpreter must be installed on any machine running said package. Through the R package [Reticulate](https://rstudio.github.io/reticulate/), the **CausalityExtraction** package downloads and configures the Python infrastructure for the user. This is the default method for using this package, and the following installation instructions will be based on the user choosing this method. If the user wants to manually perform these actions, information about the required Python version and Python package versions are described in [#configure-python-environment].
  
# Installation
## Prerequisites
The **CausalityExtraction** package was developed R Version 4.0.2.

The **CausalityExtraction** package is currently not on the Comprehensive R Archive Network (CRAN). To use, it must be installed from the package’s GitHub repository. It is strongly recommended to use the [devtools](https://www.rdocumentation.org/packages/devtools) package to assist in installation. 

The [devtools](https://www.rdocumentation.org/packages/devtools) package can be installed with the following:

```
# Install devtools from CRAN
install.packages(“devtools”)
```

## Installing CausalityExtraction
With [devtools](https://www.rdocumentation.org/packages/devtools) installed, the **CausalityExtraction** package can be installed by executing the following:

```
devtools::install_github("canfielder/CausalityExtraction")
```

## Configure Python Environment
### Python Interpreter
The **CausalityExtraction** package will automatically configure the Python environment, with minimal input by the user. Once the package is installed, all the user has to do is attempt to use the function *CausalityExtraction* or attempt to process a PDF document through the provided Shiny app, accessed from the function *LaunchApp* (see [Usage](#usage) below).

Once the package begins processing a PDF, it will search for the required Python configuration. If it has not yet been set up, the [Reticulate](https://rstudio.github.io/reticulate/) package will prompt the user to install the Miniconda installer. The prompt will generate on the RStudio console. To install, the user must enter **y**.

After installation is complete, it is recommended the user restart the R session (Session > Restart R).

**Note:** From the Miniconda documentation (https://docs.conda.io/en/latest/miniconda.html): “Miniconda is a free minimal installer for conda. It is a small, bootstrap version of Anaconda that includes only conda, Python, the packages they depend on, and a small number of other useful packages, including pip, zlib and a few others.”

The [Reticulate](https://rstudio.github.io/reticulate/) package downloads a version of Miniconda containing Python 3.6.

### Python Packages
The **CausalityExtraction** package is constructed to work with the following Python packages:

* [Joblib - Version 1.0.0](https://pypi.org/project/joblib/1.0.0/)
* [Natural Language Toolkit (NLTK) – Version 3.5](https://pypi.org/project/nltk/3.5/)
* [NumPy – Version 1.19.2](https://pypi.org/project/numpy/1.19.2/)
* [Scikit-Learn – Version 0.23.2](https://pypi.org/project/scikit-learn/0.23.2/)
* [TensorFlow – Version 2.4.0](https://pypi.org/project/tensorflow/2.4.0/)

# Usage
The main action of the **CausalityExtraction** package (as described above) is accomplished through two functions: *CausalityExtraction* and *LauchApp*.

_**CausalityExtraction**_

This function is the code-based method for performing the above action. This function accepts PDF file(s), or a folder containing PDF file(s), and then returns a table containing the information described above. 

_**LaunchApp**_

This function provides a Graphical User Interface through a Shiny app to perform the above action. The table with the processed information can then be downloaded as a CSV file. Executing *LauchApp()* from the RStudio console will launch a Shiny app. The app allows the user to select PDF files for upload and processing. 

**Note:** The app launches with the local machine’s default web browser. If the Shiny app does not launch after running this function, please check your browser's pop-up settings.

### Additional
The function *InstallCausalityExtraction* is also provided in the package. This function is to manually install the required Python packages, and should only be used if the default installation process failed. 
