#!/bin/bash

# OFT to EML Converter - Setup Script
# Installs extract_msg library for system Python

echo "🔧 Setting up Python dependencies..."

# Find available Python installations
PYTHON_PATHS=(
    "/opt/homebrew/bin/python3"
    "/usr/bin/python3"
    "/usr/local/bin/python3"
)

for python in "${PYTHON_PATHS[@]}"; do
    if [ -x "$python" ]; then
        echo "🐍 Found Python at: $python"
        
        # Check if extract_msg is already installed
        if "$python" -c "import extract_msg" 2>/dev/null; then
            echo "✅ extract_msg already installed for $python"
            continue
        fi
        
        echo "📦 Installing extract_msg..."
        
        # Try different installation methods
        if "$python" -m pip install --user extract_msg 2>/dev/null; then
            echo "✅ Installed extract_msg with --user flag"
        elif "$python" -m pip install --break-system-packages extract_msg 2>/dev/null; then
            echo "✅ Installed extract_msg with --break-system-packages"
        else
            echo "❌ Failed to install extract_msg for $python"
            continue
        fi
        
        # Verify installation
        if "$python" -c "import extract_msg; print('✅ extract_msg working!')" 2>/dev/null; then
            echo "🎉 Setup complete for $python"
            break
        else
            echo "❌ Installation verification failed for $python"
        fi
    fi
done

echo ""
echo "🔍 Testing all Python installations:"
for python in "${PYTHON_PATHS[@]}"; do
    if [ -x "$python" ]; then
        echo -n "   $python: "
        if "$python" -c "import extract_msg" 2>/dev/null; then
            echo "✅ Ready"
        else
            echo "❌ Missing extract_msg"
        fi
    fi
done

echo ""
echo "✨ Setup complete! Now run: ./build.sh"