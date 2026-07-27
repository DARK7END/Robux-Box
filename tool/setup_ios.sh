#!/usr/bin/env bash
# Generates the iOS Xcode project (which is NOT committed) and overlays the
# Robux Box iOS configuration from ios_config/. Run on macOS with Xcode +
# Flutter installed, from the repo root:
#
#   bash tool/setup_ios.sh
#
# Safe to re-run. After it finishes: `flutter build ipa` (signed) or
# `flutter build ios --release --no-codesign` (unsigned, for sideloading).
set -euo pipefail

BUNDLE_ID="com.robuxbox.app"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ Generating iOS platform files…"
flutter create . --platforms=ios --org com.robuxbox --project-name robux_box >/dev/null

echo "▶ Overlaying Robux Box iOS config…"
cp ios_config/Info.plist          ios/Runner/Info.plist
cp ios_config/AppDelegate.swift   ios/Runner/AppDelegate.swift
cp ios_config/Podfile             ios/Podfile
cp ios_config/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

echo "▶ Setting bundle identifier → ${BUNDLE_ID}"
# flutter create makes com.robuxbox.robuxBox; normalise everything to our id.
/usr/bin/sed -i '' "s/com\.robuxbox\.robuxBox/${BUNDLE_ID}/g" ios/Runner.xcodeproj/project.pbxproj || \
  sed -i "s/com\.robuxbox\.robuxBox/${BUNDLE_ID}/g" ios/Runner.xcodeproj/project.pbxproj

echo "▶ Adding GoogleService-Info.plist to the Runner target (best effort)…"
if command -v gem >/dev/null 2>&1; then
  gem install xcodeproj --no-document >/dev/null 2>&1 || sudo gem install xcodeproj --no-document >/dev/null 2>&1 || true
  ruby tool/add_ios_plist.rb || echo "  (skipped — firebase_options.dart already provides config)"
fi

echo "▶ Generating iOS app icons (best effort)…"
# --break-system-packages: macOS/modern Linux ship a PEP-668 "externally
# managed" system Python that refuses a plain `pip install`; the CI runner is
# disposable so opting out of that guard is safe. Fall back without it for
# older pip that doesn't recognise the flag.
python3 -m pip install --quiet --break-system-packages Pillow 2>/dev/null || \
  python3 -m pip install --quiet Pillow || true
python3 tool/generate_icon.py --ios || echo "  (skipped — default icon kept)"

echo "▶ Installing pods…"
flutter pub get >/dev/null
flutter gen-l10n >/dev/null || true
( cd ios && pod install ) || echo "  pod install failed — run it manually in ios/"

echo "✅ iOS project ready. Build with:"
echo "   flutter build ios --release --no-codesign   # unsigned IPA (sideload)"
echo "   ./tool/package_unsigned_ipa.sh              # wraps it into app.ipa"
