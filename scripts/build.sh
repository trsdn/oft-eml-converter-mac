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
swiftc -o "OFT-EML-Converter.app/Contents/MacOS/OFT-EML-Converter" \
    src/OFTEMLConverter.swift \
    -framework Cocoa \
    -framework Foundation

if [ $? -ne 0 ]; then
    echo "❌ Swift compilation failed"
    exit 1
fi

# Copy Python converter to app bundle
echo "📦 Copying Python converter..."
cp src/converter.py "OFT-EML-Converter.app/Contents/Resources/"

# Copy app icon if available
if [ -f "assets/icon.png" ]; then
    echo "🎨 Adding app icon..."
    # Convert PNG to ICNS format (requires iconutil on macOS)
    mkdir -p "OFT-EML-Converter.app/Contents/Resources/AppIcon.iconset"
    # For now, just copy the PNG - proper ICNS conversion would need multiple sizes
    cp assets/icon.png "OFT-EML-Converter.app/Contents/Resources/icon.png"
fi

# Copy Info.plist
echo "📋 Creating Info.plist..."
cat > "OFT-EML-Converter.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>OFT-EML-Converter</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.oft-eml-converter</string>
    <key>CFBundleName</key>
    <string>OFT EML Converter</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
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