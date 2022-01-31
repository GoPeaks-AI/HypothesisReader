# HypothesisReader

https://user-images.githubusercontent.com/59463770/116264909-a99c2a80-a748-11eb-9343-b39ab1514d25.mp4

  <!-- badges: start -->
  [![R-CMD-check](https://github.com/canfielder/HypothesisReader/workflows/R-CMD-check/badge.svg)](https://github.com/canfielder/HypothesisReader/actions)
  <!-- badges: end -->

The **HypothesisReader** R package supports the analytic methods as described in <insert academic paper>. The main action of this package is to extract any and all hypothesis and/or proposition statements found in the provided documents. Once these statements are extracted, the following key features are generated:
  
  * **Entities**: Extract both the cause and the effect entities within the statement (labeled Variable 1/2)
  * **Direction**: Classify the direction of the statement (positive, negative, non-linear)
  * **Causality**: Classify if the statement is a causal relationship (1: Causal; 0: Associative but not Causal)
  
For example, take the following sample hypothesis:
  
_**Hypothesis 1: Commitment configuration is positively associated with firm performance.**_

After this hypothesis is extracted from the source academic paper, it is reduced to it's key features,  shown below:

| Variable 1 | Variable 2 | Direction | Causality |
| :--- | :--- | :--- | :--- |
| commitment configuration | firm performance | positive | 0 |

#### A Note on Package Configuration
The **HypothesisReader** package utilizes Python in addition to R. Therefore, a Python interpreter must be installed on any machine running said package. Through the R package [Reticulate](https://rstudio.github.io/reticulate/), the **HypothesisReader** package downloads and configures the Python infrastructure for the user. This is the default method for using this package. If the user wishes to manually set-up the Python connection, information about the required Python version and Python package versions are described in [Configure Python Environment](#configure-python-environment).
  
# Installation
## Quick Set-Up
The following is for the quick set-up and installation of the R package. Further detail for each of these steps is provided in the sections below.
### Prerequisites

1. Java 8 or OpenJDK 1.8
2. R package **devtools**
3. ['rtika'](https://github.com/ropensci/rtika) package 
  
## Prerequisites
The **HypothesisReader** package was developed R Version 4.0.2.

The package requires ```Java 8``` or ```OpenJDK 1.8```. Higher versions will also work. To verify the Java version on your machine, enter ```java -version``` in a terminal. Installation information on Java can be found at [https://www.java.com/en/download/](https://www.java.com/en/download/) or [http://openjdk.java.net/install/](http://openjdk.java.net/install/).

The **HypothesisReader** package is currently not on the Comprehensive R Archive Network (CRAN). To use, it must be installed from the package’s GitHub repository. It is strongly recommended to use the [devtools](https://www.rdocumentation.org/packages/devtools) package to assist in installation. 

The [devtools](https://www.rdocumentation.org/packages/devtools) package can be installed with the following:

```
# Install devtools from CRAN
install.packages("devtools")
```

Then install ['rtika'](https://github.com/ropensci/rtika) package
  
```
# Install rtika
install.packages('rtika', repos = 'https://cloud.r-project.org')
library('rtika')
# You need to install the Apache Tika .jar once.
install_tika()
```

### Installation/ Set-Up

1. Install R package from GitHub repository
```
devtools::canfielder/HypothesisReader
```
2.	Execute function below and attempt to process a PDF file. The initial processing of a PDF will prompt Python installation.
```
HypothesisReader::LaunchApp()
```
3. At the prompt in the console, select _**y**_ to install Miniconda.
4. Restart R session (Session > Restart).
5. Package is now ready for use.

### Troubleshooting
1. If all of the required Python packages do not automatically install (which would yield an error), installation can be forced with the following function:
```
HypothesisReader::InstallPythonPackages()
```
  
## Installing HypothesisReader
With [devtools](https://www.rdocumentation.org/packages/devtools) installed, the **HypothesisReader** package can be installed by executing the following:

```
devtools::install_github("canfielder/HypothesisReader")
```

## Configure Python Environment
### Python Interpreter
The **HypothesisReader** package will automatically configure the Python environment, with minimal input by the user. Once the package is installed, all the user has to do is attempt to use the function *HypothesisReader* or attempt to process a PDF document through the provided Shiny app, accessed from the function *LaunchApp* (see [Usage](#usage) below).

Once the package begins processing a PDF, it will search for the required Python configuration. If it has not yet been set up, the [Reticulate](https://rstudio.github.io/reticulate/) package will prompt the user to install the Miniconda installer. The prompt will generate on the RStudio console. To install, the user must enter **y**.

After installation is complete, it is recommended the user restart the R session (Session > Restart R).

**Note:** From the [Miniconda documentation](https://docs.conda.io/en/latest/miniconda.html): “Miniconda is a free minimal installer for conda. It is a small, bootstrap version of Anaconda that includes only conda, Python, the packages they depend on, and a small number of other useful packages, including pip, zlib and a few others.”

The [Reticulate](https://rstudio.github.io/reticulate/) package downloads a version of Miniconda containing Python 3.6.

### Python Packages
The **HypothesisReader** package is constructed to work with the following Python packages:

* [Joblib - Version 1.0.0](https://pypi.org/project/joblib/1.0.0/)
* [Natural Language Toolkit (NLTK) – Version 3.5](https://pypi.org/project/nltk/3.5/)
* [NumPy – Version 1.19.2](https://pypi.org/project/numpy/1.19.2/)
* [Scikit-Learn – Version 0.23.2](https://pypi.org/project/scikit-learn/0.23.2/)
* [TensorFlow – Version 2.4.0](https://pypi.org/project/tensorflow/2.4.0/)

# Usage
The main action of the **HypothesisReader** package (as described above) is accomplished through two functions: *HypothesisReader* and *LauchApp*.

_**HypothesisReader**_

This function is the code-based method for performing the above action. This function accepts PDF file(s), or a folder containing PDF file(s), and then returns a table containing the information described above. 

_**LaunchApp**_

This function provides a Graphical User Interface through a Shiny app to perform the above action. The table with the processed information can then be downloaded as a CSV file. Executing *LauchApp()* from the RStudio console will launch a Shiny app. The app allows the user to select PDF files for upload and processing. 

**Note:** The app launches using the default web browser for the local machine. If the Shiny app does not launch after running this function, please check your browser's pop-up settings.

### Additional
The function *InstallPythonPackages* is also provided in the package. This function is to manually install the required Python packages, and should only be used if the default installation process failed. 
