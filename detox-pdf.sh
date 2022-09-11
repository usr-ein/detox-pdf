#!/usr/bin/env bash

# - Based off Linux Sanitize PDF by C.D. and QuickRecon of r/scuba
#   at https://github.com/scuba-tech/Linux-Sanitize-PDF
# - Itself based off of Windows Sanitize-PDF.bat by Kerbalnut
#   at https://github.com/Kerbalnut/Sanitize-PDF

# Method and security notes:
# https://security.stackexchange.com/questions/103323/effectiveness-of-flattening-a-pdf-to-remove-malware
# https://www.ghostscript.com/Documentation.html
# https://www.ghostscript.com/doc/9.23/Install.htm
# https://linux.die.net/man/1/gs
# https://www.ghostscript.com/doc/current/Use.htm if [ "$#" -lt 1 ]; then

if [ "$#" -lt 1 ]; then
    printf "%s\n\n" "$(cat <<EOF
Takes PDF(s) and output each page as a PNG. 

Optionaly, you can output a PDF stripped of all active objects, trackers,
auto-launch print dialogues, and other JS crap. 
In PDF export, it will preserve OCR/text, as well as chapters.

The processed PDF files will be renamed from .pdf to .pdf.unsafe to prevent you from opening them by mistake (happens to the best of us).
EOF
)"
    echo "Usage: $0 [--pdf] 1.pdf [2.pdf ...]" >&2;
    echo "" >&2;
    echo -e "\t--pdf\tOutput stripped PDF files instead of PNGs of pages, a bit less safe than the default\n" >&2;
    
    printf "%s\n" "$(cat <<EOF
DISCLAIMER:
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

I haven't tested if this makes infected PDFs safe 100%. However, it's my best attempt 
at it, and makes me a bit less worried about opening random PDFs from unreputable sources.
Do what you want with this, but it's not my problem.
EOF
)"
    exit 1
fi

function detoxPdf() {
    # -dSAFER is the default as of 9.56 (maybe earlier too?), but to be sure, let's enable it
    
    dir="$(dirname "$1")";
    base="$(basename "$1")";

    echo -ne "Processing ${1}...\t";

    if [ "$outputAsPdf" -eq 1 ]; then
        outBase="${base%.*}-detoxed.pdf";
        out="${dir}/$outBase";
        gs -dSAFER -dBATCH -dNOPAUSE \
            -sDEVICE=pdfwrite \
            -sOutputFile="$out" \
            "$1" >/dev/null
        echo -e "\t-->\t$outBase";
    else
        outDir="${dir}/${base%.*}-detoxed-png";
        if [ ! -d "$outDir" ]; then
            mkdir "$outDir";
        fi
        out="${outDir}/${base%.*}-detoxed-%03d.png";
        # Change -r300x300 this to make the PNGs higher res
        # with r300x300, I got 3508 x 2479 pixels on an A4 page. I think it's quite enough
        gs -dSAFER -dBATCH -dNOPAUSE \
            -sDEVICE=png16m \
            -r300x300 \
            -sOutputFile="$out" \
            "$1" >/dev/null
        echo -e "\t-->\t${outDir}/*.png";
    fi
    mv "$1" "${1}.unsafe";
}

function checkDeps() {
    # Check bash version
    if [ "${BASH_VERSION:0:1}" -lt 4 ]; then
        echo "Bash 4 or later is required for this script!" >&2;
        echo "Current version: $BASH_VERSION" >&2;
        exit 1
    fi

    if ! command -v gs > /dev/null 2>&1; then
        echo "GhostScript must be installed for this to work!" >&2;
    fi

    if ! command -v wget > /dev/null 2>&1; then
        echo "wget must be installed!" >&2;
    fi

    # That page has the following string in it: "The latest release is Ghostscript 9.56.1 (2022-04-04)."
    lastGsVersion=$(wget https://www.ghostscript.com/releases/index.html -q -O - | sed -E -e '/The latest release is Ghostscript/!d; s/^.* Ghostscript ([0-9\.]+).*$/\1/g');
    installedGsVersion=$(gs --version);

    if [ "$lastGsVersion" != "$installedGsVersion" ]; then
        echo "You're not running the latest GhostScript version!";
        echo -e "\tCurrently installed:\t $installedGsVersion";
        echo -e "\tLast available:\t\t $lastGsVersion";
        echo "This could leave you vulnerable to PDF reader exploits!";
        echo " ==> Update before continuing";
        exit 1;
    fi
}

checkDeps;

outputAsPdf=0;


printf "%s" "$(cat <<EOF
I haven't tested if this makes infected PDFs safe 100%. However, it's my best attempt 
at it, and makes me a bit less worried about opening random PDFs from unreputable sources.
Do what you want with this, but it's not my problem.

EOF
)";

if [ "$1" == "--pdf" ]; then
    echo "                        /!\\ WARNING /!\\" >&2;
    echo "Exporting as sanitized PDFs instead of PNGs." >&2;
    echo "This will likely NOT protect against a deliberately-malicious PDF, " >&2;
    echo "especially ones that target GhostScript and/or have image exploits." >&2;
    shift;
    outputAsPdf=1;
fi

# I tried to multithread this loop with background jobs and "wait", and it's slower than single-thread:
# multi-threaded:   ./detox-pdf.sh --pdf testPdfDir  389.96s user 240.65s system 372% cpu 2:49.40 total
# single-threaded:  ./detox-pdf.sh --pdf testPdfDir  230.72s user 22.38s system 97% cpu 4:19.46 total

for inputPdf in "$@"; do
    if [ -d "$inputPdf" ]; then
        echo "Recursively detoxxing ${inputPdf}...";
        while read -r inputPdfFound; do
            detoxPdf "$inputPdfFound";
        done < <(find "$inputPdf" -iname '*.pdf');
        echo "Done exploring ${inputPdf}!";
        continue;
    fi
    detoxPdf "$inputPdf";
done

echo "All done." >&2;
