# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-27

### Changed
- **Complete SwiftUI rewrite** — Modern native macOS UI replacing the old NSApplication/Cocoa implementation
- Minimum macOS version raised from 10.15 to **14.0 (Sonoma)**
- Python search now includes `~/Library/Application Support/OFT-EML-Converter/venv`

### Added
- **Auto-dependency installation** — App automatically creates a Python venv and installs `extract_msg` on first launch
- **No-Python detection** — Friendly "Download Python" screen with link to python.org if Python 3 is not installed
- **Pip bootstrapping** — Falls back to `ensurepip` or `get-pip.py` if pip is missing from the venv
- SF Symbols with animated visual feedback on drag hover
- Progress spinner during file conversion with file count
- Recent conversions list with success/failure status
- "Reveal in Finder" button for converted files
- "Clear" button for conversion history
- Help menu with link to GitHub repository
- Automatic dark mode support (built into SwiftUI)

### Fixed
- Python detection now actually runs `python3 --version` instead of just checking file existence (catches the macOS CLT stub)

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