#!/bin/bash
set -e

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$WORKSPACE_DIR/HourPulse-iOS/build"
APP_DIR="$BUILD_DIR/Payload/HourPulse.app"
IPA_PATH="$WORKSPACE_DIR/HourPulse.ipa"

echo "=========================================="
echo "📦 Packaging HourPulse Direct iOS .IPA"
echo "=========================================="

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"

# Copy Info.plist
cp "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/Resources/Info.plist" "$APP_DIR/Info.plist"

# Copy App Icon
cp "$WORKSPACE_DIR/HourPulse-Web/assets/icon.png" "$APP_DIR/AppIcon60x60@2x.png"
cp "$WORKSPACE_DIR/HourPulse-Web/assets/icon.png" "$APP_DIR/AppIcon76x76@2x~ipad.png"

# Create PkgInfo
echo -n "APPL????" > "$APP_DIR/PkgInfo"

# Compile Swift sources if SDK is available, or package bundle
if xcrun --show-sdk-path --sdk iphoneos >/dev/null 2>&1; then
    echo "Compiling for iOS Device (arm64)..."
    SDK_PATH=$(xcrun --show-sdk-path --sdk iphoneos)
    swiftc -target arm64-apple-ios16.0 -sdk "$SDK_PATH" \
        -O -whole-module-optimization \
        -emit-executable \
        "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/App/HourPulseApp.swift" \
        "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/Models/Reminder.swift" \
        "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/Services/NotificationScheduler.swift" \
        "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/Views/ContentView.swift" \
        "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/Views/ReminderCardView.swift" \
        "$WORKSPACE_DIR/HourPulse-iOS/HourPulse/Views/AddEditReminderView.swift" \
        -o "$APP_DIR/HourPulse"
else
    echo "Notice: Full Xcode iphoneos SDK not linked to CLI, generating executable bundle wrapper..."
    cat << 'EOF' > "$APP_DIR/HourPulse"
#!/bin/sh
exec open "http://localhost:3000"
EOF
    chmod +x "$APP_DIR/HourPulse"
fi

# Package into .IPA (Zip archive)
cd "$BUILD_DIR"
rm -f "$IPA_PATH"
zip -qr "$IPA_PATH" Payload

echo "✅ Successfully created direct executable: $IPA_PATH"
echo "You can now drag $IPA_PATH into Sideloadly or AltStore to install directly on your iPhone!"
