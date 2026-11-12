# Calru

Calru is a lightweight, local-first revenue, gross-profit and financial calculation studio.

## Targets

- Windows
- Linux
- macOS
- Android
- iOS

## Project status

Initial application scaffold is being established. The first milestone focuses on a cross-platform Flutter shell, precise financial calculations, local persistence, and screenshot import/review. OCR is designed as a platform adapter so mobile and desktop engines can be integrated without coupling financial calculations to a specific OCR provider.

## Development

Install the Flutter stable SDK, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <device>
```

Desktop builds require the platform toolchains documented by Flutter. iOS builds require macOS and Xcode.

## Accuracy

Calru uses decimal arithmetic for money. Estimates are clearly labeled, and imported OCR values must be reviewed before they are saved as financial records.

## Privacy

The initial architecture is local-first. No account or remote service is required for core calculations.
