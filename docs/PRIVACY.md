# Privacy and data handling

Calru is designed to work locally without an account or hosted backend.

## What stays on the device

- Financial records and the selected display-currency label are stored in local app preferences.
- Screenshot images are selected by the user through the operating system file picker.
- OCR is performed locally by Google ML Kit on Android/iOS or the locally installed Tesseract executable on desktop.
- OCR text and suggested amounts remain in the app until the user confirms a record.

Calru does not include an analytics SDK, advertising SDK, remote API, cloud account, or automatic upload feature.

## Exports and backups

CSV exports and JSON backups contain the user's financial records. They are written only after the user chooses an export destination. Imported JSON backups are read from the file selected by the user. Users are responsible for protecting exported files and backups.

## Local storage security

Calru does not encrypt its local SharedPreferences data or exported files itself. The operating system and device account protections apply. Use device encryption and a strong device passcode, and do not place backups in shared folders or untrusted cloud locations.

## OCR limitations

OCR can misread numbers, decimal separators, labels, or table columns. Extracted data is not treated as verified. Always compare suggested values with the source image before saving.

## Financial disclaimer

Calru is a calculation and record-keeping aid. Tax estimates are based only on the percentage entered by the user. The app does not provide regulated financial advice, determine tax liability, file returns, or connect to banks or payment services.
