# Calru

Calru is a local-first financial workspace for estimating revenue, gross profit, margins, break-even sales, tax, and net profit. It is built with Flutter and shares one Dart codebase across desktop and mobile.

## Features

- **Financial calculator:** revenue, cost of goods sold, operating expenses, gross profit, gross margin, break-even revenue, estimated tax, and after-tax profit.
- **Exact money arithmetic:** calculations use decimal/rational arithmetic rather than binary floating-point for monetary values.
- **Dashboard:** combined revenue, costs, gross profit, margin, estimated tax, and net profit across saved records.
- **Record history:** searchable records with edit and delete actions.
- **Screenshot OCR:** import receipts, invoices, sales dashboards, and other financial screenshots; extract text and suggest amounts for review.
- **Human verification:** OCR output is editable and never becomes a saved record until the user confirms it.
- **Mobile OCR:** Google ML Kit on Android and iOS.
- **Desktop OCR:** local Tesseract executable on Linux, Windows, and macOS.
- **Data portability:** export records to CSV, create JSON backups, and restore or merge backups.
- **Local-first storage:** records and preferences are stored on the device; no account or hosted backend is required.
- **Currency label:** choose USD, EUR, GBP, INR, LKR, SGD, AUD, or CAD. This changes the displayed currency label only; it does not perform foreign-exchange conversion. Keep records in one currency per dataset.

## Supported platforms

| Platform | Development / build target | Notes |
| --- | --- | --- |
| Android | APK | Android SDK required |
| iOS | iOS app (15.5+) | macOS and Xcode required; App Store distribution requires signing |
| Windows | Desktop app | Visual Studio with Desktop development with C++ workload |
| macOS | Desktop app | Xcode command-line tools required |
| Linux | Desktop app | GTK development libraries, CMake, Ninja, and Clang |

Flutter officially supports native deployment to these mobile and desktop families. See the [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms) and [desktop guide](https://docs.flutter.dev/platform-integration/desktop).

## Requirements

- Flutter stable SDK (CI uses the current stable channel).
- Native SDK/toolchain for the platform you want to build.
- Tesseract OCR installed and available on PATH for desktop screenshot recognition.

## Run locally

From the repository root:

```sh
sh tool/bootstrap_platforms.sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

To run on a specific target:

```sh
flutter devices
flutter run -d <device-id>
```

## Build locally

```sh
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build ios --release --no-codesign
```

Only build targets supported by the current host toolchain. iOS and macOS builds require macOS. See [docs/RELEASE.md](docs/RELEASE.md) for release packaging and signing requirements.

## Screenshot OCR setup

See [docs/SCREENSHOT-OCR.md](docs/SCREENSHOT-OCR.md) for installation steps, supported behavior, privacy notes, and OCR accuracy limitations.

## Data, privacy, and accuracy

- Financial records stay on the device unless the user explicitly exports or shares a backup.
- CSV exports are intended for spreadsheets and further analysis.
- JSON backups preserve records, currency preference, and tax-rate inputs.
- OCR is probabilistic and can misread digits, decimal separators, currency symbols, or table columns. Always verify extracted figures against the original source.
- Tax calculations are estimates based on the tax rate entered by the user. Calru does not determine tax liability, file taxes, or replace professional accounting advice.
- Calru is an estimation and record-keeping tool, not a bank, payment processor, or accounting ledger.

## CI

GitHub Actions runs formatting checks, static analysis, unit/widget tests, and release builds for Android, Linux, Windows, macOS, and iOS. Build artifacts are attached to successful workflow runs for testing.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the application structure, [docs/PRIVACY.md](docs/PRIVACY.md) for data handling, and [docs/RELEASE.md](docs/RELEASE.md) for distribution requirements.
