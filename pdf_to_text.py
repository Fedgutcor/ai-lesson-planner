#!/usr/bin/env python3
import sys

try:
    import PyPDF2

    pdf_path = sys.argv[1]

    with open(pdf_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        text = []

        for page in reader.pages:
            text.append(page.extract_text())

        print('\n'.join(text))

except ImportError:
    # PyPDF2 no disponible, intentar con pypdf
    try:
        from pypdf import PdfReader

        reader = PdfReader(sys.argv[1])
        text = []

        for page in reader.pages:
            text.append(page.extract_text())

        print('\n'.join(text))

    except ImportError:
        sys.stderr.write("Error: PyPDF2 o pypdf no están instalados\n")
        sys.exit(1)

except Exception as e:
    sys.stderr.write(f"Error: {str(e)}\n")
    sys.exit(1)
