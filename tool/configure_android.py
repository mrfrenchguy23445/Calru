#!/usr/bin/env python3
from pathlib import Path
import re

app_dir = Path("android/app")
if not app_dir.is_dir():
    raise SystemExit("Android app project was not generated.")

gradle_file = next(
    (path for path in (app_dir / "build.gradle.kts", app_dir / "build.gradle") if path.exists()),
    None,
)
if gradle_file is None:
    raise SystemExit("Android app Gradle build file was not found.")

rules = """# ML Kit references optional recognizer modules for scripts that Calru does not bundle.
# Calru currently configures the Latin recognizer; silence R8 warnings for unused script modules.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
"""
(app_dir / "proguard-rules.pro").write_text(rules, encoding="utf-8")

gradle = gradle_file.read_text(encoding="utf-8")
if "proguard-rules.pro" not in gradle:
    pattern = re.compile(r"(buildTypes\\s*\\{\\s*release\\s*\\{)", re.MULTILINE)
    if gradle_file.suffix == ".kts":
        config = 'proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
    else:
        config = "proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'"
    gradle, count = pattern.subn(r"\\1\\n            " + config, gradle, count=1)
    if count != 1:
        raise SystemExit("Could not add the ML Kit R8 rules to the Android release build.")
    gradle_file.write_text(gradle, encoding="utf-8")

print("Configured Android R8 rules for the Latin-only ML Kit recognizer.")
