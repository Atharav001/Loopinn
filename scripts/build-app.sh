#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

swift build --disable-sandbox -c release
binary_dir=$(swift build --disable-sandbox -c release --show-bin-path)
app_dir="$project_dir/dist/Loopinn.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$binary_dir/Loopinn" "$app_dir/Contents/MacOS/Loopinn"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Loopinn</string>
  <key>CFBundleIdentifier</key><string>com.atharav.loopinn</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Loopinn</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSCalendarsFullAccessUsageDescription</key><string>Loopinn reads selected calendars after you connect Apple Calendar, and publishes only events you explicitly approve.</string>
  <key>NSCalendarsWriteOnlyAccessUsageDescription</key><string>Loopinn publishes a planned block only after you confirm that event.</string>
  <key>NSMicrophoneUsageDescription</key><string>Loopinn records only while you dictate an activity.</string>
  <key>NSSpeechRecognitionUsageDescription</key><string>Loopinn transcribes your dictated activity for your review before saving.</string>
</dict></plist>
PLIST
echo "$app_dir"
