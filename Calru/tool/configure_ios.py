#!/usr/bin/env python3
from pathlib import Path
import re

podfile = Path("ios/Podfile")
if podfile.exists():
    text = podfile.read_text(encoding="utf-8")
    platform_pattern = re.compile(r"^\s*#?\s*platform :ios,.*$", re.MULTILINE)
    if platform_pattern.search(text):
        text = platform_pattern.sub("platform :ios, '15.5'", text, count=1)
    else:
        text = "platform :ios, '15.5'\n" + text

    if "installer.pods_project.build_configurations.each do |config|" not in text:
        text = text.replace(
            "post_install do |installer|",
            """post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
    config.build_settings['EXCLUDED_ARCHS[sdk=*]'] = 'armv7'
  end""",
            1,
        )

    target_settings = """    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      config.build_settings['EXCLUDED_ARCHS[sdk=*]'] = 'armv7'
    end"""
    text = text.replace(
        "    flutter_additional_ios_build_settings(target)",
        target_settings,
        1,
    )
    podfile.write_text(text, encoding="utf-8")

project = Path("ios/Runner.xcodeproj/project.pbxproj")
if project.exists():
    text = project.read_text(encoding="utf-8")
    text = re.sub(
        r"(IPHONEOS_DEPLOYMENT_TARGET\s*=\s*)[^;]+;",
        r"\g<1>15.5;",
        text,
    )
    project.write_text(text, encoding="utf-8")

print("Configured iOS deployment target 15.5 for Google ML Kit.")
