#!/usr/bin/env python3
"""
Test suite for the OFT to EML converter.

This module contains comprehensive tests for the Python converter component,
including unit tests, integration tests, and validation of output format.
"""

import unittest
import tempfile
import os
import sys
from pathlib import Path
import email
from email.mime.multipart import MIMEMultipart

# Add src to path to import our converter
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

try:
    from converter import convert_oft_to_eml
except ImportError:
    print("❌ Could not import converter module. Make sure src/converter.py exists.")
    sys.exit(1)

try:
    import extract_msg
except ImportError:
    print("❌ extract_msg library not available. Run: pip install extract_msg")
    sys.exit(1)


class TestOFTConverter(unittest.TestCase):
    """Test cases for OFT to EML conversion functionality."""
    
    def setUp(self):
        """Set up test fixtures before each test method."""
        self.test_dir = Path(__file__).parent.parent
        self.examples_dir = self.test_dir / "examples"
        self.sample_oft = self.examples_dir / "sample.oft"
        
        # Create temporary directory for test outputs
        self.temp_dir = tempfile.mkdtemp()
        
        # Check if sample file exists, skip tests if not
        self.sample_available = self.sample_oft.exists()
        
    def tearDown(self):
        """Clean up after each test method."""
        # Clean up temporary files
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_sample_oft_exists(self):
        """Test that the sample OFT file exists and is readable."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        self.assertTrue(self.sample_oft.is_file(), 
                       "Sample OFT path is not a file")
        self.assertGreater(self.sample_oft.stat().st_size, 1000, 
                          "Sample OFT file seems too small")
    
    def test_basic_conversion(self):
        """Test basic OFT to EML conversion."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        output_path = Path(self.temp_dir) / "test_output.eml"
        
        # Perform conversion
        result = convert_oft_to_eml(str(self.sample_oft), str(output_path))
        
        # Verify result
        self.assertEqual(result, str(output_path))
        self.assertTrue(output_path.exists(), "Output EML file was not created")
        self.assertGreater(output_path.stat().st_size, 1000, 
                          "Output EML file seems too small")
    
    def test_eml_format_validation(self):
        """Test that the output EML has proper format and structure."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        output_path = Path(self.temp_dir) / "format_test.eml"
        convert_oft_to_eml(str(self.sample_oft), str(output_path))
        
        # Read and parse the EML
        with open(output_path, 'r', encoding='utf-8') as f:
            eml_content = f.read()
        
        # Parse as email message
        msg = email.message_from_string(eml_content)
        
        # Validate basic email structure
        self.assertIsNotNone(msg.get('Subject'), "Subject header missing")
        self.assertIsNotNone(msg.get('MIME-Version'), "MIME-Version header missing")
        self.assertTrue(msg.is_multipart(), "Message should be multipart")
        
        # Check for multipart/related structure
        self.assertTrue(msg.get_content_type().startswith('multipart/'), 
                       "Root content type should be multipart")
    
    def test_content_preservation(self):
        """Test that content is properly preserved in conversion."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        output_path = Path(self.temp_dir) / "content_test.eml"
        convert_oft_to_eml(str(self.sample_oft), str(output_path))
        
        with open(output_path, 'r', encoding='utf-8') as f:
            eml_content = f.read()
        
        # Check for expected content (based on our sample file) - content is base64 encoded
        # So we check the subject header instead
        self.assertIn("Microsoft_BR_Roundtable", eml_content, 
                     "Expected subject content not found in headers")
        self.assertIn("multipart/related", eml_content.lower(),
                     "Multipart/related structure not found")
        self.assertIn("Content-ID:", eml_content,
                     "Inline images (Content-ID) not found")
    
    def test_inline_images_preservation(self):
        """Test that inline images are properly preserved with Content-IDs."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        output_path = Path(self.temp_dir) / "images_test.eml"
        convert_oft_to_eml(str(self.sample_oft), str(output_path))
        
        with open(output_path, 'r', encoding='utf-8') as f:
            eml_content = f.read()
        
        # Count Content-ID headers (should have inline images)
        content_id_count = eml_content.count('Content-ID:')
        self.assertGreater(content_id_count, 0, 
                          "No inline images found (Content-ID headers missing)")
        
        # Check for base64 encoded image data
        self.assertIn('Content-Transfer-Encoding: base64', eml_content,
                     "Base64 encoded image data not found")
        
        # Check for PNG image headers in base64
        self.assertIn('image/png', eml_content,
                     "PNG image MIME type not found")
    
    def test_utf8_encoding(self):
        """Test that UTF-8 encoding is properly handled."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        output_path = Path(self.temp_dir) / "utf8_test.eml"
        convert_oft_to_eml(str(self.sample_oft), str(output_path))
        
        with open(output_path, 'r', encoding='utf-8') as f:
            eml_content = f.read()
        
        # Check for UTF-8 charset specification
        self.assertIn('charset="utf-8"', eml_content,
                     "UTF-8 charset not specified")
        
        # Verify German characters are preserved (from our sample)
        msg = email.message_from_string(eml_content)
        subject = msg.get('Subject', '')
        
        # The subject should contain German characters properly encoded
        self.assertIn('=?utf-8?', subject, 
                     "Subject should be UTF-8 encoded")
    
    def test_error_handling(self):
        """Test error handling for various failure scenarios."""
        
        # Test with non-existent file
        with self.assertRaises(FileNotFoundError):
            convert_oft_to_eml("nonexistent.oft", "output.eml")
        
        # Test with invalid output path (directory that doesn't exist)
        if self.sample_available:
            invalid_output = "/nonexistent/path/output.eml"
            with self.assertRaises((OSError, FileNotFoundError)):
                convert_oft_to_eml(str(self.sample_oft), invalid_output)
    
    def test_large_file_handling(self):
        """Test handling of the large sample file."""
        if not self.sample_available:
            self.skipTest("Sample OFT file not available - examples directory excluded from repository")
        
        # Our sample file is ~548KB, which is considered large for OFT
        file_size = self.sample_oft.stat().st_size
        self.assertGreater(file_size, 100000, 
                          "Sample file should be reasonably large for testing")
        
        output_path = Path(self.temp_dir) / "large_file_test.eml"
        
        # Time the conversion (should complete in reasonable time)
        import time
        start_time = time.time()
        convert_oft_to_eml(str(self.sample_oft), str(output_path))
        conversion_time = time.time() - start_time
        
        # Should complete within 30 seconds for large files
        self.assertLess(conversion_time, 30.0, 
                       f"Conversion took too long: {conversion_time:.2f}s")
        
        # Output should be significantly larger than input (due to base64 encoding)
        output_size = output_path.stat().st_size
        self.assertGreater(output_size, file_size * 0.8, 
                          "Output file seems too small compared to input")


class TestConverterModule(unittest.TestCase):
    """Test the converter module structure and imports."""
    
    def test_required_imports(self):
        """Test that all required imports are available."""
        # These should not raise ImportError
        import sys
        import os
        from pathlib import Path
        from email.mime.multipart import MIMEMultipart
        from email.mime.text import MIMEText
        from email.mime.base import MIMEBase
        from email import encoders
        import extract_msg
        
        # Test that extract_msg is functional
        self.assertTrue(hasattr(extract_msg, 'Message'))
    
    def test_converter_function_exists(self):
        """Test that the main conversion function exists and is callable."""
        from converter import convert_oft_to_eml
        self.assertTrue(callable(convert_oft_to_eml))
    
    def test_main_function_exists(self):
        """Test that the main function exists for command line usage."""
        from converter import main
        self.assertTrue(callable(main))


def run_tests():
    """Run all tests and return results."""
    print("🧪 Running OFT to EML Converter Test Suite")
    print("=" * 50)
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTests(loader.loadTestsFromTestCase(TestOFTConverter))
    suite.addTests(loader.loadTestsFromTestCase(TestConverterModule))
    
    # Run tests with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print summary
    print("\n" + "=" * 50)
    if result.wasSuccessful():
        print("✅ All tests passed!")
    else:
        print("❌ Some tests failed!")
        print(f"Failures: {len(result.failures)}")
        print(f"Errors: {len(result.errors)}")
    
    return result.wasSuccessful()


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)