#!/bin/bash
# Builds "Grade Tracker.app" and installs it to ~/Applications.
# Only needed if you change index.html or main.swift.
set -euo pipefail
cd "$(dirname "$0")"
APP="build/Grade Tracker.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -o "$APP/Contents/MacOS/GradeTracker" main.swift

# icon
swift make_icon.swift build/icon.png
ICONSET=build/AppIcon.iconset && mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s build/icon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) build/icon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cp index.html "$APP/Contents/Resources/index.html"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Grade Tracker</string>
  <key>CFBundleDisplayName</key><string>Grade Tracker</string>
  <key>CFBundleIdentifier</key><string>com.dongyundi.gradetracker</string>
  <key>CFBundleExecutable</key><string>GradeTracker</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.education</string>
</dict></plist>
PLIST

codesign --force --deep --sign - "$APP"
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Grade Tracker.app"
cp -R "$APP" "$HOME/Applications/Grade Tracker.app"
echo "Installed: $HOME/Applications/Grade Tracker.app"
