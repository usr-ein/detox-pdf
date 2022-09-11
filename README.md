# Detox PDF
Takes PDF(s) and output each page as a PNG. 

Optionaly, you can output a PDF stripped of all active objects, trackers, auto-launch print dialogues, and other JS crap. 
In PDF export, it will preserve OCR/text, as well as chapters.

The processed PDF files will be renamed from .pdf to .pdf.unsafe to prevent you from opening them by mistake (happens to the best of us).


## Install
```sh
git clone https://github.com/usr-ein/detox-pdf
chmod +x detox-pdf/detox-pdf.sh
```

## Usage

Converts all the PDFs inside this folder to folders containing PNGs of each page. Explores the directory recursively.
```
./detox-pdf/detox-pdf.sh path/to/folderWithPdfs
```

Converts the specified files to folders of PNGs.
```
./detox-pdf/detox-pdf.sh my_file_1.pdf my_file_2.pdf
```

Converts the specified PDF file to another PDF file that's a bit more safe.
```
./detox-pdf/detox-pdf.sh --pdf my_file_1.pdf
```

## Sources

 - Based off [Linux Sanitize PDF by C.D. and QuickRecon of r/scuba](https://github.com/scuba-tech/Linux-Sanitize-PDF)
 - Itself based off of [Windows Sanitize-PDF.bat by Kerbalnut](https://github.com/Kerbalnut/Sanitize-PDF)
 - The project name `detox` is inspired by [the eponymous CLI utility](https://github.com/dharple/detox) meant to sanitize problematic filenames. In our case, we sanitize problematic PDF files.

 Main features I added:
 
 - Check that we're running the LATEST version of GhostScript, and refuse to run otherwise.
   - If a malicious PDF is using a GhostScript CVE, then this makes sure you're using the patched version, always

 - Rename processed PDFs to `.pdf.unsafe` to prevent opening the unsafe PDF by mistake

 - Export input PDFs to a collection of PNG files:
    `file1.pdf --> file1-detoxed-png/file1-detoxed-001.png, file1-detoxed-002.png, etc..`

 - Provide multiple PDFs:
    `./detox-pdf.sh file1.pdf file2.pdf file3.pdf`

 - Provide a directory and recursively detox all the PDFs in it:
    `./detox-pdf.sh ~/Documents` will detox `~/Documents/file1.pdf`, `~/Documents/file2.pdf` etc.

