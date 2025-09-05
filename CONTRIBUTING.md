# Contributing to OFT to EML Converter

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## How to Contribute

### 🐛 Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/yourusername/oft-eml-converter-mac/issues)
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (macOS version, Python version)
   - Sample OFT file (if possible)

### ✨ Suggesting Features

1. Check existing [Issues](https://github.com/yourusername/oft-eml-converter-mac/issues) for similar requests
2. Create a new issue with:
   - Clear description of the feature
   - Use case and benefits
   - Possible implementation approach

### 🔧 Code Contributions

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a new branch for your changes
4. **Make** your changes following our coding standards
5. **Test** your changes thoroughly
6. **Submit** a pull request

## Development Setup

### Prerequisites
- macOS 10.15+ with Xcode Command Line Tools
- Python 3.7+
- Git

### Setup Steps
```bash
# Clone your fork
git clone https://github.com/yourusername/oft-eml-converter-mac.git
cd oft-eml-converter-mac

# Setup Python dependencies
./scripts/setup.sh

# Build the app
./scripts/build.sh

# Test the app
open OFT-EML-Converter.app
```

## Coding Standards

### Swift Code
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### Python Code
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where appropriate
- Add docstrings for functions and classes
- Handle errors gracefully

### General
- Write clear, descriptive commit messages
- Keep commits focused (one logical change per commit)
- Update documentation for new features
- Add tests when applicable

## Project Architecture

```
Swift macOS App (UI Layer)
    ↓ subprocess
Python Converter (Logic Layer)  
    ↓ library
extract_msg (Parsing Layer)
    ↓ output
EML File (Data Layer)
```

### Key Components

1. **OFTEMLConverter.swift**: Native macOS UI with drag & drop
2. **converter.py**: Python subprocess for MSG parsing
3. **Build Scripts**: Automated building and setup
4. **Error Handling**: Comprehensive user feedback

## Testing

### Manual Testing
- Test with various OFT file types
- Verify conversion quality (images, formatting, encoding)
- Test error scenarios (missing files, permissions, etc.)
- Check UI responsiveness and feedback

### Test Files
- Use the provided `examples/sample.oft`
- Create additional test cases for edge cases
- Verify output EML files in email clients

## Documentation

- Update README.md for user-facing changes
- Add inline comments for complex code
- Update this CONTRIBUTING.md for process changes
- Include screenshots for UI changes

## Release Process

1. Update version numbers in relevant files
2. Update CHANGELOG.md with new features/fixes
3. Create a new release on GitHub
4. Include pre-built app bundle for users

## Getting Help

- Check existing [Issues](https://github.com/yourusername/oft-eml-converter-mac/issues)
- Create a new issue with the "question" label
- Be specific about your development environment and problem

## Code of Conduct

- Be respectful and constructive in all interactions
- Focus on the technical aspects of contributions
- Help maintain a welcoming environment for all contributors

Thank you for contributing to make OFT to EML conversion better for everyone! 🚀