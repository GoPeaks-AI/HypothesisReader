'''
The following script contains the functions related to converting PDF files
to raw text with the PDFMiner package.
'''

# PACKAGES --------------------------------------------------------------------
import io

from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.pdfpage import PDFPage

# FUNCTIONS -------------------------------------------------------------------
'''
CONVERT PDF FILE TO TEXT

The following function converts a PDF file to text. 

INPUT
 - path: path to PDF file (string)

OUTPUT
 - pdf_txt: raw text of input PDF
'''

def pdf_to_text(path):
    # Open PDF File
    pdf_file = open(path, 'rb')
    
    # Initialze / Settings
    rsrcmgr = PDFResourceManager()
    retstr = io.StringIO()
    codec = 'utf-8'
    laparams = LAParams()
    device = TextConverter(rsrcmgr, retstr, laparams=laparams)
    
    # Create PDF Interpreter Object
    interpreter = PDFPageInterpreter(rsrcmgr, device)
    
    # Process Each PDF Page
    for page in PDFPage.get_pages(pdf_file):
        interpreter.process_page(page)
        pdf_txt =  retstr.getvalue()
    
    return(pdf_txt)
