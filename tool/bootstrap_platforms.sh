#!/usr/bin/env sh
set -eu

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter stable is required. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter create --project-name calru --platforms=android,ios,linux,macos,windows .

# Keep the repository's own tests instead of the generated starter test.
if [ ! -f test/widget_test.dart ]; then
  rm -f test/widget_test.dart
fi
