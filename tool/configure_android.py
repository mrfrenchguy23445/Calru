#!/usr/bin/env python3
from pathlib import Path

app_dir = Path("android/app")
if not app_dir.is_dir():
    raise SystemExit("Android app project was not generated.")

rules = """# ML Kit references optional recognizer modules for scripts that Calru does not bundle.
# Calru currently configures the Latin recognizer; silence R8 warnings for unused script modules.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
"""
(app_dir / "proguard-rules.pro").write_text(rules, encoding="utf-8")
print("Configured Android R8 rules for the Latin-only ML Kit recognizer.")
