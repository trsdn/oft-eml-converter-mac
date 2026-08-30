#!/bin/bash

# OFT to EML Converter - macOS App Builder
# Builds native macOS drag-and-drop application

echo "🔨 Building OFT to EML Converter for macOS..."

# Check if Python converter exists
if [ ! -f "src/converter.py" ]; then
    echo "❌ Error: src/converter.py not found"
    exit 1
fi

# Check if Swift source exists
if [ ! -f "src/OFTEMLConverter.swift" ]; then
    echo "❌ Error: src/OFTEMLConverter.swift not found"
    exit 1
fi

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p "OFT-EML-Converter.app/Contents/"{MacOS,Resources}

# Build Swift executable
echo "🏗️  Compiling Swift code..."
ARCH=$(uname -m)
swiftc -o "OFT-EML-Converter.app/Contents/MacOS/OFT-EML-Converter" \
    src/OFTEMLConverter.swift \
    -parse-as-library \
    -framework Cocoa \
    -framework SwiftUI \
    -framework UniformTypeIdentifiers \
    -target ${ARCH}-apple-macosx14.0

if [ $? -ne 0 ]; then
    echo "❌ Swift compilation failed"
    exit 1
fi

# Copy Python converter to app bundle
echo "📦 Copying Python converter..."
cp src/converter.py "OFT-EML-Converter.app/Contents/Resources/"

# Create and install app icon
if [ -f "assets/icon.png" ]; then
    echo "🎨 Creating app icon..."
    
    # Create iconset directory
    ICONSET_DIR="OFT-EML-Converter.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Create multiple icon sizes using sips (built-in macOS tool)
    sips -z 16 16     assets/icon.png --out "$ICONSET_DIR/icon_16x16.png" >/dev/null 2>&1
    sips -z 32 32     assets/icon.png --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null 2>&1
    sips -z 32 32     assets/icon.png --out "$ICONSET_DIR/icon_32x32.png" >/dev/null 2>&1
    sips -z 64 64     assets/icon.png --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null 2>&1
    sips -z 128 128   assets/icon.png --out "$ICONSET_DIR/icon_128x128.png" >/dev/null 2>&1
    sips -z 256 256   assets/icon.png --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null 2>&1
    sips -z 256 256   assets/icon.png --out "$ICONSET_DIR/icon_256x256.png" >/dev/null 2>&1
    sips -z 512 512   assets/icon.png --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null 2>&1
    sips -z 512 512   assets/icon.png --out "$ICONSET_DIR/icon_512x512.png" >/dev/null 2>&1
    sips -z 1024 1024 assets/icon.png --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null 2>&1
    
    # Convert to icns format
    iconutil -c icns "$ICONSET_DIR" -o "OFT-EML-Converter.app/Contents/Resources/AppIcon.icns" 2>/dev/null
    
    # Clean up temporary iconset
    rm -rf "$ICONSET_DIR"
    
    # Also copy the original PNG for fallback
    cp assets/icon.png "OFT-EML-Converter.app/Contents/Resources/icon.png"
    
    echo "✅ App icon installed"
fi

# Copy Info.plist
echo "📋 Creating Info.plist..."

# Identity is derived, never hand-maintained (criterion I06). APP_VERSION is set
# by the release build from the tag; a local build falls back to the newest tag
# and finally to a marker that is obviously not a release.
APP_VERSION="${APP_VERSION:-}"
if [ -z "$APP_VERSION" ]; then
    APP_VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
fi
if [ -z "$APP_VERSION" ]; then
    APP_VERSION="0.0.0-dev"
fi
BUILD_VERSION="${BUILD_VERSION:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"
REPOSITORY_URL="https://github.com/trsdn/oft-eml-converter-mac"
COPYRIGHT="Copyright © $(date +%Y) Torsten Mahr. MIT licensed."

cat > "OFT-EML-Converter.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>OFT-EML-Converter</string>
    <key>CFBundleIdentifier</key>
    <string>com.trsdn.oft-eml-converter</string>
    <key>CFBundleName</key>
    <string>OFT EML Converter</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHumanReadableCopyright</key>
    <string>${COPYRIGHT}</string>
    <key>TRSDNRepositoryURL</key>
    <string>${REPOSITORY_URL}</string>
    <key>TRSDNIssueTrackerURL</key>
    <string>${REPOSITORY_URL}/issues</string>
    <key>TRSDNLicense</key>
    <string>MIT</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>oft</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Outlook Template</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "   version ${APP_VERSION} (build ${BUILD_VERSION})"

# Make executable
chmod +x "OFT-EML-Converter.app/Contents/MacOS/OFT-EML-Converter"

echo "✅ Build complete!"
echo ""
echo "📱 OFT-EML-Converter.app is ready to use"
echo ""
echo "🚀 To launch: open OFT-EML-Converter.app"
echo "📂 Drag .oft files onto the app window to convert"
echo ""
echo "⚠️  Requirements:"
echo "   - Python 3 with extract_msg library installed"
echo "   - Run './setup.sh' if you need to install extract_msg"
