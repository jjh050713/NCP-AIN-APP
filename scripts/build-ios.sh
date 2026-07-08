#!/usr/bin/env bash
# Build NCP-AIN iOS app on macOS with Xcode 15+
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/NCPAINApp/NCPAINApp.xcodeproj"
SCHEME="NCPAINApp"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/NCPAINApp.xcarchive"
IPA_PATH="$BUILD_DIR/NCPAINApp.ipa"
EXPORT_DIR="$BUILD_DIR/export"

echo "==> Clean"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archive (Release)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"

echo "==> Export IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT/NCPAINApp/ExportOptions.plist"

if [[ -f "$EXPORT_DIR/NCPAINApp.ipa" ]]; then
  cp "$EXPORT_DIR/NCPAINApp.ipa" "$IPA_PATH"
  echo "✅ IPA: $IPA_PATH"
else
  echo "⚠️  IPA export failed. Open Xcode and set your Development Team."
  echo "   Archive created at: $ARCHIVE_PATH"
  exit 1
fi
