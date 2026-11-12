# Release and distribution

## Automated release builds

Pushing a tag matching `v*` starts the release workflow. It builds and attaches:

- Android release APK
- Linux x64 desktop bundle
- Windows x64 desktop bundle
- macOS desktop app bundle
- iOS device app bundle (unsigned)

The CI workflow separately validates formatting, static analysis, unit/widget tests, and builds all five targets on their native GitHub-hosted runner families.

## Signing and store publication

The repository does not contain private signing credentials. The generated packages are build artifacts, not yet signed or notarized store submissions.

Before publishing:
- **Android:** configure a private release keystore and Gradle signing configuration; never commit the keystore or passwords.
- **iOS:** the app targets iOS 15.5 or newer. Configure Apple Developer signing, provisioning profiles, App Store Connect credentials, and a signed archive on macOS.
- **Windows:** sign the installer/executable with an organization code-signing certificate if distributing broadly.
- **macOS:** sign with a Developer ID certificate and notarize for Gatekeeper distribution.
- **Linux:** package for the target distributions and consider signing repository/package metadata.

Do not put certificates, keystores, provisioning profiles, API keys, or passwords in the repository. Use GitHub Actions secrets or a secure local signing environment.

## Before a public release

- Run the complete CI workflow and inspect every platform build.
- Test OCR with real receipts, invoices, and dashboard screenshots on physical devices.
- Verify CSV export and JSON restore on every target.
- Test backup compatibility with older records.
- Review app permissions, privacy disclosures, app icons, display names, and platform metadata.
- Add platform-specific signing and store assets.
- Confirm accounting/tax wording and regional currency behavior.
- Test accessibility, keyboard navigation, responsive layouts, and large record collections.

## Known limitations

- OCR suggestions are heuristic and require user verification.
- Desktop OCR requires Tesseract installed on the user's system and available on PATH.
- iOS cannot be built or signed on Windows/Linux; use macOS with Xcode.
- No cloud sync, multi-user accounts, bank integrations, invoicing, payment processing, or automatic tax filing is included.
- The app stores records locally using SharedPreferences. For very large ledgers, a database migration would be appropriate.
