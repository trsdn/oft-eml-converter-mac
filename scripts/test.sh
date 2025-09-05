#!/bin/bash

# Test Suite Runner for OFT to EML Converter
# Runs both Python and Swift tests

set -e  # Exit on any error

echo "🧪 OFT to EML Converter - Test Suite Runner"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track overall results
PYTHON_TESTS_PASSED=false
SWIFT_TESTS_PASSED=false

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check prerequisites
echo ""
print_status $BLUE "📋 Checking Prerequisites..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    print_status $RED "❌ Python 3 not found. Please install Python 3."
    exit 1
else
    print_status $GREEN "✅ Python 3 found: $(python3 --version)"
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    print_status $RED "❌ Swift not found. Please install Xcode Command Line Tools."
    exit 1
else
    print_status $GREEN "✅ Swift found: $(swift --version | head -n 1)"
fi

# Check if extract_msg is available
if python3 -c "import extract_msg" 2>/dev/null; then
    print_status $GREEN "✅ extract_msg library available"
else
    print_status $YELLOW "⚠️  extract_msg not found. Running setup..."
    if ./scripts/setup.sh; then
        print_status $GREEN "✅ extract_msg installed successfully"
    else
        print_status $RED "❌ Failed to install extract_msg"
        exit 1
    fi
fi

# Check if required files exist
echo ""
print_status $BLUE "📁 Checking Required Files..."

REQUIRED_FILES=(
    "src/converter.py"
    "src/OFTEMLConverter.swift"
    "tests/test_converter.py"
    "tests/test_app.swift"
)

OPTIONAL_FILES=(
    "examples/sample.oft"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status $GREEN "✅ $file"
    else
        print_status $RED "❌ $file missing"
        exit 1
    fi
done

for file in "${OPTIONAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status $GREEN "✅ $file (optional)"
    else
        print_status $YELLOW "⚠️  $file not found (optional - tests will skip)"
    fi
done

# Run Python tests
echo ""
print_status $BLUE "🐍 Running Python Tests..."
echo "----------------------------------------"

if python3 tests/test_converter.py; then
    PYTHON_TESTS_PASSED=true
    print_status $GREEN "✅ Python tests completed successfully"
else
    print_status $RED "❌ Python tests failed"
fi

echo ""

# Run Swift tests
print_status $BLUE "🍎 Running Swift/macOS App Tests..."
echo "----------------------------------------"

if swift tests/test_app.swift; then
    SWIFT_TESTS_PASSED=true
    print_status $GREEN "✅ Swift tests completed successfully"
else
    print_status $RED "❌ Swift tests failed"
fi

# Additional integration test - build the actual app
echo ""
print_status $BLUE "🔨 Integration Test - Building App..."
echo "----------------------------------------"

# Clean up any existing app
rm -rf OFT-EML-Converter.app

if ./scripts/build.sh > /dev/null 2>&1; then
    print_status $GREEN "✅ App builds successfully"
    APP_BUILD_SUCCESS=true
    
    # Test if the app bundle is properly formed
    if [ -f "OFT-EML-Converter.app/Contents/MacOS/OFT-EML-Converter" ] && \
       [ -f "OFT-EML-Converter.app/Contents/Resources/converter.py" ] && \
       [ -f "OFT-EML-Converter.app/Contents/Info.plist" ]; then
        print_status $GREEN "✅ App bundle structure is correct"
    else
        print_status $RED "❌ App bundle structure is incomplete"
        APP_BUILD_SUCCESS=false
    fi
else
    print_status $RED "❌ App build failed"
    APP_BUILD_SUCCESS=false
fi

# Performance test with sample file
if $PYTHON_TESTS_PASSED && [ -f "examples/sample.oft" ]; then
    echo ""
    print_status $BLUE "⚡ Performance Test..."
    echo "----------------------------------------"
    
    START_TIME=$(python3 -c "import time; print(time.time())")
    if python3 src/converter.py examples/sample.oft test_performance_output.eml > /dev/null 2>&1; then
        END_TIME=$(python3 -c "import time; print(time.time())")
        DURATION=$(python3 -c "print(f'{$END_TIME - $START_TIME:.2f}')")
        
        if [ -f "test_performance_output.eml" ]; then
            FILE_SIZE=$(wc -c < "test_performance_output.eml")
            print_status $GREEN "✅ Performance test completed in ${DURATION}s (output: ${FILE_SIZE} bytes)"
            rm -f test_performance_output.eml
        else
            print_status $RED "❌ Performance test failed - no output file"
        fi
    else
        print_status $RED "❌ Performance test failed"
    fi
fi

# Final summary
echo ""
print_status $BLUE "📊 Test Results Summary"
echo "============================================"

echo ""
echo "Test Results:"
if $PYTHON_TESTS_PASSED; then
    print_status $GREEN "✅ Python Tests: PASSED"
else
    print_status $RED "❌ Python Tests: FAILED"
fi

if $SWIFT_TESTS_PASSED; then
    print_status $GREEN "✅ Swift Tests: PASSED"
else
    print_status $RED "❌ Swift Tests: FAILED"
fi

if $APP_BUILD_SUCCESS; then
    print_status $GREEN "✅ App Build: PASSED"
else
    print_status $RED "❌ App Build: FAILED"
fi

echo ""

# Overall result
if $PYTHON_TESTS_PASSED && $SWIFT_TESTS_PASSED && $APP_BUILD_SUCCESS; then
    print_status $GREEN "🎉 ALL TESTS PASSED!"
    echo ""
    echo "Your OFT to EML Converter is ready for use:"
    echo "  • Run: open OFT-EML-Converter.app"
    echo "  • Or build again with: ./scripts/build.sh"
    exit 0
else
    print_status $RED "❌ SOME TESTS FAILED!"
    echo ""
    echo "Please fix the failing tests before deploying."
    exit 1
fi