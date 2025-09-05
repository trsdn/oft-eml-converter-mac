# AI Agent Development Guide

This document provides guidance for AI agents working with the OFT to EML Converter codebase.

## Project Context

This is a native macOS application that converts Outlook Template (.oft) files to EML format. The project uses a hybrid architecture combining Swift for the native UI and Python for reliable MSG parsing.

### Key Technical Concepts

- **Swift/Cocoa**: Native macOS drag & drop interface
- **Python Bridge**: Subprocess communication to leverage extract_msg library
- **MSG Format**: Complex compound document format requiring specialized parsing
- **EML Output**: RFC 5322 compliant email format with multipart/related structure
- **Inline Images**: Base64 encoded with Content-ID headers for proper display

## Architecture Overview

```
┌─────────────────┐    subprocess    ┌──────────────────┐
│   Swift App     │ ───────────────> │  Python Script  │
│ (Native UI)     │                  │ (extract_msg)    │
└─────────────────┘                  └──────────────────┘
         │                                     │
         v                                     v
┌─────────────────┐                  ┌──────────────────┐
│  User drags     │                  │   Perfect EML    │
│  .oft files     │                  │   with images    │
└─────────────────┘                  └──────────────────┘
```

## Critical Implementation Notes

### ⚠️ MSG Parsing - DO NOT IMPLEMENT MANUALLY
The MSG/OFT format is extremely complex. **Always use the existing Python converter with extract_msg library**. Previous attempts at manual Swift parsing resulted in corrupted output.

**❌ Wrong Approach:**
```swift
// Don't try to parse MSG manually
class MSGParser {
    func parseCompoundDocument() { ... }
}
```

**✅ Correct Approach:**
```swift
// Use subprocess to call proven Python converter
let process = Process()
process.executableURL = URL(fileURLWithPath: pythonPath)
process.arguments = [converterPath, input.path, output.path]
```

### Python Environment Detection

The app must handle multiple Python installations:
1. Virtual environment (`venv/bin/python`) - highest priority
2. Homebrew Python (`/opt/homebrew/bin/python3`)
3. System Python (`/usr/bin/python3`)

Always test that the chosen Python has `extract_msg` available before attempting conversion.

## File Structure

```
├── src/
│   ├── OFTEMLConverter.swift    # Native macOS app (main implementation)
│   └── converter.py             # Python converter (DO NOT MODIFY)
├── scripts/
│   ├── build.sh                # App bundle builder
│   ├── setup.sh                # Dependency installer
│   └── test.sh                 # Test runner
├── tests/
│   ├── test_converter.py       # Python unit tests
│   └── test_app.swift         # Swift integration tests
└── examples/
    └── sample.oft              # Test file (~548KB with images)
```

## Development Guidelines

### Testing Strategy
1. **Python Tests**: Unit tests for converter functionality
2. **Swift Tests**: Integration tests for macOS app
3. **Build Tests**: Full compilation and bundle creation
4. **Performance Tests**: Large file handling (>5MB)

### Common Issues and Solutions

**"Conversion failed" Error**
- Usually means extract_msg not installed
- Run `./scripts/setup.sh` to fix dependencies

**"Python not found" Error**
- Check Python path detection logic in Swift app
- Ensure Python is in expected locations

**Output Quality Issues**
- Never modify the Python converter
- All quality issues should be addressed via extract_msg updates

### Build Process

```bash
./scripts/setup.sh    # Install dependencies
./scripts/test.sh     # Run full test suite
./scripts/build.sh    # Create app bundle
```

## Code Modification Guidelines

### Safe to Modify
- Swift UI components and drag/drop handling
- Error messages and user feedback
- Build scripts and documentation
- Test cases and validation

### DO NOT MODIFY
- `src/converter.py` - This is the proven conversion engine
- Core subprocess communication logic
- Python dependency requirements

### When Adding Features

1. **UI Enhancements**: Modify Swift app only
2. **Conversion Features**: Update Python converter carefully with thorough testing
3. **New File Types**: Ensure extract_msg supports them first

## Testing Requirements

Before any modification:
1. Run full test suite: `./scripts/test.sh`
2. Test with real OFT files, especially large ones with images
3. Verify EML output opens correctly in email clients
4. Check performance with files >10MB

## Debugging

### Verbose Output
```bash
# Enable detailed conversion logging
python3 src/converter.py input.oft output.eml --verbose

# Check subprocess communication
# Add debug prints in Swift app's runPythonConverter method
```

### Common Debug Checks
- Python path resolution
- extract_msg library availability
- File permissions and paths
- Subprocess stdout/stderr
- EML format validation

## Performance Expectations

- Small OFT (<1MB): ~1-2 seconds
- Large OFT (>5MB): ~3-5 seconds  
- Memory usage: <50MB peak
- Output size: ~1.3x input size (due to base64 encoding)

## Quality Assurance

The converted EML must have:
- ✅ Proper RFC 5322 headers
- ✅ multipart/related structure for images
- ✅ Base64 encoded inline images with Content-ID
- ✅ UTF-8 encoding for international text
- ✅ Original HTML and text formatting preserved

Any modification that breaks these requirements is unacceptable.

---

**Remember**: This project's success depends on leveraging proven libraries (extract_msg) rather than reimplementing complex formats. Focus on the native macOS experience while maintaining conversion reliability.