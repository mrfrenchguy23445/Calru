# Screenshot OCR

Calru supports a review-first screenshot workflow.

- Android and iOS: Google ML Kit text recognition.
- Linux, Windows and macOS: Tesseract OCR through the local `tesseract` executable.
- Every detected amount remains editable.
- OCR output is never saved as a financial record until the user confirms it.

## Desktop setup

Install Tesseract OCR and ensure the `tesseract` command is available on PATH.

- Debian/Ubuntu: `sudo apt install tesseract-ocr`
- Fedora: `sudo dnf install tesseract`
- macOS with Homebrew: `brew install tesseract`
- Windows: install the Tesseract OCR distribution and add its installation directory to PATH.

The initial desktop implementation invokes the local executable; screenshots and extracted text stay on the device.

## Accuracy note

OCR is probabilistic. Calru deliberately requires human review because visually similar digits, currency symbols, decimal separators, and table columns can be misread. Automatic field suggestions are heuristics, not accounting decisions.
