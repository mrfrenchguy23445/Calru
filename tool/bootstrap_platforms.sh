#!/usr/bin/env sh
set -eu

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter stable is required. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter create --org com.calru --project-name calru --platforms=android,ios,linux,macos,windows .

PYTHON=python3
if ! command -v "$PYTHON" >/dev/null 2>&1; then
  PYTHON=python
fi
if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "Python 3 is required to configure native platform projects."
  exit 1
fi

"$PYTHON" tool/configure_android.py
"$PYTHON" tool/configure_ios.py
