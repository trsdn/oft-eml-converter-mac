# Testing Guide

This document describes the comprehensive test suite for the OFT to EML Converter.

## Test Suite Overview

The project includes three types of tests:

1. **Python Unit Tests** (`tests/test_converter.py`) - Test the core conversion logic
2. **Swift Integration Tests** (`tests/test_app.swift`) - Test the macOS app functionality  
3. **End-to-End Tests** (`scripts/test.sh`) - Full integration testing with build verification

## Quick Test Run

```bash
# Run all tests
./scripts/test.sh

# Run only Python tests
cd tests && python3 test_converter.py

# Run only Swift tests  
swift tests/test_app.swift
```

## Test Coverage

### Python Converter Tests (`test_converter.py`)

**Unit Tests:**
- ✅ **Sample File Validation** - Verifies test OFT file exists and is readable
- ✅ **Basic Conversion** - Tests OFT to EML conversion functionality
- ✅ **EML Format Validation** - Validates RFC 5322 compliant output
- ✅ **Content Preservation** - Ensures content is properly maintained
- ✅ **Inline Images** - Verifies images are embedded with Content-IDs
- ✅ **UTF-8 Encoding** - Tests international character handling
- ✅ **Error Handling** - Tests failure scenarios and edge cases
- ✅ **Large File Handling** - Performance testing with large OFT files

**Module Tests:**
- ✅ **Import Validation** - Verifies all required libraries are available
- ✅ **Function Interface** - Tests public API of converter module

### macOS App Tests (`test_app.swift`)

**Environment Tests:**
- ✅ **File Structure** - Validates project structure and required files
- ✅ **Python Detection** - Tests automatic Python environment detection
- ✅ **Dependency Check** - Verifies extract_msg library availability

**Integration Tests:**
- ✅ **Subprocess Execution** - Tests Python subprocess communication
- ✅ **File Operations** - Tests file I/O and temporary directory handling
- ✅ **Conversion Process** - End-to-end conversion through app logic
- ✅ **Error Handling** - Tests error scenarios and proper exception handling

### Build Integration Tests (`test.sh`)

**System Tests:**
- ✅ **Prerequisites** - Validates Python 3, Swift, and dependencies
- ✅ **File Integrity** - Checks all required project files exist
- ✅ **Python Tests** - Runs complete Python test suite
- ✅ **Swift Tests** - Runs complete Swift test suite
- ✅ **App Building** - Tests actual app compilation and bundle creation
- ✅ **Performance** - Measures conversion speed and output quality

## Test Data

### Sample Files
- `examples/sample.oft` - Real-world OFT file (~548KB) with:
  - German text content
  - HTML and plain text versions
  - 3 inline PNG images
  - Complex MIME structure

### Expected Outputs
- **EML Size**: ~750KB+ (larger due to base64 encoding)
- **Content-IDs**: 3 inline images with proper Content-ID headers
- **Encoding**: UTF-8 with proper German character handling
- **Structure**: multipart/related with multipart/alternative

## Running Specific Tests

### Python Tests Only
```bash
cd tests
python3 test_converter.py
```

**Expected Output:**
```
🧪 Running OFT to EML Converter Test Suite
==================================================
test_basic_conversion ... ok
test_content_preservation ... ok
test_eml_format_validation ... ok
...
✅ All tests passed!
```

### Swift Tests Only
```bash
swift tests/test_app.swift
```

**Expected Output:**
```
🧪 Running macOS App Test Suite
==================================================
📁 Testing Environment Setup...
✅ Source directory exists
✅ Swift source file exists
...
🎉 All tests passed!
```

### Full Test Suite
```bash
./scripts/test.sh
```

**Expected Output:**
```
🧪 OFT to EML Converter - Test Suite Runner
============================================
📋 Checking Prerequisites...
✅ Python 3 found: Python 3.13.0
✅ Swift found: swift-driver version: 1.109.2
...
🎉 ALL TESTS PASSED!
```

## Test Failure Scenarios

### Common Issues and Solutions

**"extract_msg not found"**
```bash
./scripts/setup.sh  # Install dependencies
```

**"Sample OFT file not available"**
- Ensure `examples/sample.oft` exists
- Check file permissions are readable

**"Swift compilation failed"**
- Install Xcode Command Line Tools: `xcode-select --install`
- Check Swift version compatibility

**"Python subprocess failed"**
- Verify Python path in system
- Check extract_msg installation
- Review file permissions

## Continuous Integration

For CI/CD systems, use:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    ./scripts/setup.sh
    ./scripts/test.sh
```

## Performance Benchmarks

**Expected Performance:**
- Small OFT (<1MB): ~1-2 seconds
- Large OFT (>5MB): ~3-5 seconds  
- Inline images: +1-2 seconds per image
- Memory usage: <50MB peak

**Performance Test:**
```bash
time python3 src/converter.py examples/sample.oft output.eml
```

## Test Development

### Adding New Tests

**Python Tests:**
1. Add test method to `TestOFTConverter` class
2. Follow naming convention: `test_feature_name`
3. Use descriptive assertions with meaningful messages

**Swift Tests:**
1. Add test function to `test_app.swift`
2. Update `runAllTests()` to include new test
3. Follow error handling patterns

### Test Data
- Keep test files small but realistic
- Include edge cases (unicode, large files, etc.)
- Document expected outputs

## Debugging Tests

**Verbose Test Output:**
```bash
python3 tests/test_converter.py -v  # Python verbose
swift tests/test_app.swift          # Swift always verbose
```

**Manual Debugging:**
```bash
# Test specific conversion manually
python3 src/converter.py examples/sample.oft debug_output.eml

# Check output
file debug_output.eml
head -20 debug_output.eml
```

## Test Maintenance

- Run tests before each commit
- Update tests when adding features
- Keep test data current and relevant
- Review test coverage regularly

The test suite ensures reliability and quality of the OFT to EML conversion process across both Python and Swift components.
