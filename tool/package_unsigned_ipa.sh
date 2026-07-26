#!/usr/bin/env bash
# Wraps an unsigned Runner.app (from `flutter build ios --release --no-codesign`)
# into an unsigned app.ipa suitable for sideloading tools (iLoader / Sideloadly /
# AltStore) that re-sign with your free Apple ID.
#
#   flutter build ios --release --no-codesign
#   bash tool/package_unsigned_ipa.sh
#
# Output: build/ios/ipa/RobuxBox-unsigned.ipa
set -euo pipefail

APP="build/ios/iphoneos/Runner.app"
OUT_DIR="build/ios/ipa"
OUT="${OUT_DIR}/RobuxBox-unsigned.ipa"

if [ ! -d "$APP" ]; then
  echo "❌ $APP not found. Run: flutter build ios --release --no-codesign"
  exit 1
fi

rm -rf build/ios/_payload "$OUT"
mkdir -p build/ios/_payload/Payload "$OUT_DIR"
cp -R "$APP" build/ios/_payload/Payload/
( cd build/ios/_payload && zip -qr "../ipa/RobuxBox-unsigned.ipa" Payload )
rm -rf build/ios/_payload

echo "✅ Unsigned IPA: $OUT"
echo "   Sideload it with iLoader / Sideloadly / AltStore using your Apple ID."
