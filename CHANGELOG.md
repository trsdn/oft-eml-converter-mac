# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-09-05

### Added
- Initial release of OFT to EML Converter for macOS
- Native Swift/Cocoa drag & drop interface
- Python-based MSG parsing using extract_msg library  
- Perfect EML output with inline images and HTML content
- Automatic Python environment detection
- Comprehensive error handling and user feedback
- Professional application icon integration
- Support for macOS 10.15+ (Catalina and later)

### Features
- **Drag & Drop Conversion**: Native macOS file handling
- **Perfect Format Preservation**: 
  - HTML and plain text content
  - Inline images with Content-IDs
  - Multipart/related MIME structure
  - UTF-8 encoding for international text
- **Reliable MSG Parsing**: Uses proven extract_msg library
- **Smart Python Detection**: Automatically finds Python with dependencies
- **Professional UI**: Native dialogs and error messages
- **Batch Support**: Multiple file drag & drop

### Technical Specifications
- **Input Formats**: Microsoft Outlook Template (.oft) files
- **Output Format**: RFC 5322 compliant EML files
- **Architecture**: Swift UI + Python subprocess
- **Dependencies**: Python 3.7+ with extract_msg library
- **File Size Support**: Handles large files (750KB+ outputs tested)

### Development Tools
- Automated build system with `scripts/build.sh`
- Dependency setup with `scripts/setup.sh`
- Professional project structure for open source
- Comprehensive documentation and contributing guidelines

## [Unreleased]

### Planned Features
- Progress indicators for large file processing
- Batch processing queue with cancel support
- Additional output formats (MSG to EML direct conversion)
- Drag & drop to Dock icon support
- Quick Look plugin for OFT files

### Possible Improvements
- Persistent Python process for faster repeated conversions
- Custom app icon sizes for different contexts
- Preferences panel for Python path configuration
- Integration with Apple's Shortcuts app