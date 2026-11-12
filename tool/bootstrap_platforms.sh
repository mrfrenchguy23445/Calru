#!/usr/bin/env sh
set -eu

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter stable is required. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter create --org com.calru --project-name calru --platforms=android,ios,linux,macos,windows .
python3 tool/configure_ios.py
