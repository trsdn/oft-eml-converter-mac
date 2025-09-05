#!/usr/bin/env python3
"""
Create a minimal OFT test file for CI/CD testing.

Since OFT files are complex Microsoft compound documents, this creates
a minimal binary file that can be used for basic testing scenarios
when a real OFT file isn't available.
"""

import os
import struct

def create_minimal_oft_file(filename="sample.oft"):
    """Create a minimal OFT-like file for testing purposes."""
    
    # This creates a very basic binary file that mimics some OFT file structure
    # It's not a real OFT but serves for testing error handling and basic I/O
    
    with open(filename, "wb") as f:
        # Write some basic MSG file headers (simplified)
        # Real MSG files are complex compound documents, but this gives us something to test with
        f.write(b'\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1')  # OLE signature
        f.write(b'\x00' * 504)  # Padding to make it look like a file with content
        
        # Add some fake message properties
        f.write(b'FAKE_OFT_TEST_FILE_FOR_TESTING')
        f.write(b'\x00' * 100)
    
    print(f"Created minimal test file: {filename}")
    return filename

if __name__ == "__main__":
    create_minimal_oft_file()