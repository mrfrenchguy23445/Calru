#!/usr/bin/env sh
set -eu

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter stable is required. Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter create --org com.calru --project-name calru --platforms=android,ios,linux,macos,windows .
if command -v python3 >/dev/null 2>&1; then
  python3 tool/configure_android.py
  python3 tool/configure_ios.py
  python3 tool/configure_android.py
elif command -v python >/dev/null 2>&1; then
  python tool/configure_ios.py
  python tool/configure_android.py
else
  echo "Python 3 is required to configure the iOS deployment target."
  exit 1
fi
