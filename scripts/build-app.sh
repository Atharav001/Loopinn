#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

xcodebuild -project Loopinn.xcodeproj -scheme Loopinn -configuration Release \
  -derivedDataPath "$project_dir/.build/xcode" CODE_SIGNING_ALLOWED=NO build

app_dir="$project_dir/dist/Loopinn.app"
mkdir -p "$project_dir/dist"
rm -rf "$app_dir"
cp -R "$project_dir/.build/xcode/Build/Products/Release/Loopinn.app" "$app_dir"
echo "$app_dir"
