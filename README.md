# Calru

Calru is a lightweight, local-first revenue, gross-profit and financial calculation studio.

## Supported targets

- Windows
- Linux
- macOS
- Android
- iOS

The shared Flutter application and financial calculation code are used across all targets. Native platform folders are generated from the Flutter SDK so the repository does not need to carry thousands of generated platform files.

## Current foundation

- Revenue, COGS, gross profit, gross margin and estimated net profit calculator.
- Decimal arithmetic for monetary values.
- Local record persistence and selectable display currency.
- Screenshot import, OCR, editable extracted text and manual value correction.
- Mobile OCR through Google ML Kit.
- Desktop OCR through the locally installed Tesseract executable.
- Review-before-save workflow: OCR suggestions are never silently treated as verified financial data.

## Bootstrap

Install the Flutter stable SDK and the native prerequisites for your target platform. From the repository root:

```sh
sh tool/bootstrap_platforms.sh
flutter pub get
flutter analyze
flutter test
```

Then launch on a connected device or desktop target:

```sh
flutter devices
flutter run -d <device-id>
```

Linux desktop builds require the Flutter Linux toolchain and GTK development libraries. Windows builds require Visual Studio with the Desktop development with C++ workload. macOS and iOS builds require macOS and Xcode. Android builds require the Android SDK.

## Screenshot OCR

See [docs/SCREENSHOT-OCR.md](docs/SCREENSHOT-OCR.md) for desktop Tesseract installation and OCR accuracy notes.

## Accuracy and privacy

Calru uses decimal arithmetic for money and keeps core calculations local. OCR is probabilistic, so extracted values remain editable and require user confirmation. The initial app does not require an account or remote service.
