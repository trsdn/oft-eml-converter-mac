#!/usr/bin/env swift

/*
 * Test suite for the macOS OFT to EML Converter application.
 * 
 * This Swift script tests the macOS app functionality including:
 * - Python environment detection
 * - Subprocess execution
 * - File handling and error cases
 * - Integration with the Python converter
 */

import Foundation
import Cocoa

// Test configuration
struct TestConfig {
    static let testDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    static let srcDir = testDir.appendingPathComponent("src")
    static let examplesDir = testDir.appendingPathComponent("examples")
    static let sampleOFT = examplesDir.appendingPathComponent("sample.oft")
    static let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("oft-eml-tests")
}

// Test results tracking
class TestResults {
    var passed = 0
    var failed = 0
    var testNames: [String] = []
    var failures: [String] = []
    
    func record(test: String, success: Bool, message: String = "") {
        testNames.append(test)
        if success {
            passed += 1
            print("✅ \(test)")
        } else {
            failed += 1
            failures.append("\(test): \(message)")
            print("❌ \(test): \(message)")
        }
    }
    
    func printSummary() {
        print("\n" + String(repeating: "=", count: 50))
        print("🧪 macOS App Test Results")
        print(String(repeating: "=", count: 50))
        print("Total tests: \(passed + failed)")
        print("Passed: \(passed)")
        print("Failed: \(failed)")
        
        if failed > 0 {
            print("\n❌ Failures:")
            for failure in failures {
                print("  - \(failure)")
            }
        } else {
            print("\n🎉 All tests passed!")
        }
    }
    
    var success: Bool { failed == 0 }
}

// Mock implementation of our app's conversion logic for testing
class TestableConverter {
    
    enum ConversionError: Error {
        case pythonNotFound
        case conversionFailed(String)
        case fileNotFound
    }
    
    func findPython() -> String? {
        let pythonPaths = [
            TestConfig.testDir.appendingPathComponent("venv/bin/python").path,
            "/opt/homebrew/bin/python3",
            "/usr/bin/python3",
            "/usr/local/bin/python3"
        ]
        
        for path in pythonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    func testPythonWithExtractMsg(pythonPath: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["-c", "import extract_msg; print('OK')"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func runConversion(input: URL, output: URL) throws {
        guard let python = findPython() else {
            throw ConversionError.pythonNotFound
        }
        
        guard FileManager.default.fileExists(atPath: input.path) else {
            throw ConversionError.fileNotFound
        }
        
        let converterPath = TestConfig.srcDir.appendingPathComponent("converter.py").path
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: python)
        process.arguments = [converterPath, input.path, output.path]
        process.currentDirectoryURL = TestConfig.testDir
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw ConversionError.conversionFailed(errorString)
            }
        } catch {
            throw ConversionError.conversionFailed(error.localizedDescription)
        }
    }
}

// Test functions
func testEnvironmentSetup(results: TestResults) {
    // Test 1: Source directory exists
    results.record(
        test: "Source directory exists",
        success: FileManager.default.fileExists(atPath: TestConfig.srcDir.path),
        message: "src/ directory not found"
    )
    
    // Test 2: Swift source file exists
    let swiftFile = TestConfig.srcDir.appendingPathComponent("OFTEMLConverter.swift")
    results.record(
        test: "Swift source file exists",
        success: FileManager.default.fileExists(atPath: swiftFile.path),
        message: "src/OFTEMLConverter.swift not found"
    )
    
    // Test 3: Python converter exists
    let converterFile = TestConfig.srcDir.appendingPathComponent("converter.py")
    results.record(
        test: "Python converter exists",
        success: FileManager.default.fileExists(atPath: converterFile.path),
        message: "src/converter.py not found"
    )
    
    // Test 4: Sample OFT file exists
    results.record(
        test: "Sample OFT file exists",
        success: FileManager.default.fileExists(atPath: TestConfig.sampleOFT.path),
        message: "examples/sample.oft not found"
    )
}

func testPythonEnvironment(results: TestResults) {
    let converter = TestableConverter()
    
    // Test 5: Python executable found
    let pythonPath = converter.findPython()
    results.record(
        test: "Python executable found",
        success: pythonPath != nil,
        message: "No Python interpreter found in expected paths"
    )
    
    guard let python = pythonPath else { return }
    
    // Test 6: Python has extract_msg
    results.record(
        test: "Python has extract_msg library",
        success: converter.testPythonWithExtractMsg(pythonPath: python),
        message: "extract_msg library not available in Python"
    )
}

func testFileOperations(results: TestResults) {
    // Create temporary directory
    do {
        try FileManager.default.createDirectory(
            at: TestConfig.tempDir,
            withIntermediateDirectories: true
        )
    } catch {
        results.record(
            test: "Create temporary directory",
            success: false,
            message: "Failed to create temp dir: \(error)"
        )
        return
    }
    
    // Test 7: Temporary directory created
    results.record(
        test: "Temporary directory created",
        success: FileManager.default.fileExists(atPath: TestConfig.tempDir.path)
    )
    
    // Test 8: Can write to temporary directory
    let testFile = TestConfig.tempDir.appendingPathComponent("test.txt")
    let writeSuccess = FileManager.default.createFile(
        atPath: testFile.path,
        contents: "test".data(using: .utf8)
    )
    results.record(
        test: "Write to temporary directory",
        success: writeSuccess,
        message: "Cannot write to temporary directory"
    )
    
    // Clean up test file
    try? FileManager.default.removeItem(at: testFile)
}

func testConversionProcess(results: TestResults) {
    let converter = TestableConverter()
    
    guard FileManager.default.fileExists(atPath: TestConfig.sampleOFT.path) else {
        results.record(
            test: "Conversion process test",
            success: false,
            message: "Sample OFT file not available"
        )
        return
    }
    
    let outputFile = TestConfig.tempDir.appendingPathComponent("test_output.eml")
    
    // Test 9: Basic conversion
    do {
        try converter.runConversion(input: TestConfig.sampleOFT, output: outputFile)
        results.record(
            test: "Basic OFT to EML conversion",
            success: FileManager.default.fileExists(atPath: outputFile.path),
            message: "Conversion completed but output file not created"
        )
    } catch {
        results.record(
            test: "Basic OFT to EML conversion",
            success: false,
            message: "Conversion failed: \(error)"
        )
        return
    }
    
    // Test 10: Output file size validation
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: outputFile.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        results.record(
            test: "Output file size validation",
            success: fileSize > 10000, // Should be at least 10KB
            message: "Output file too small (\(fileSize) bytes)"
        )
    } catch {
        results.record(
            test: "Output file size validation",
            success: false,
            message: "Could not read output file attributes"
        )
    }
    
    // Test 11: Output file content validation
    do {
        let content = try String(contentsOf: outputFile)
        let hasSubject = content.contains("Subject:")
        let hasMIME = content.contains("MIME-Version:")
        let hasContentID = content.contains("Content-ID:")
        
        results.record(
            test: "Output file content validation",
            success: hasSubject && hasMIME && hasContentID,
            message: "Missing expected content (Subject: \(hasSubject), MIME: \(hasMIME), Content-ID: \(hasContentID))"
        )
    } catch {
        results.record(
            test: "Output file content validation",
            success: false,
            message: "Could not read output file content"
        )
    }
}

func testErrorHandling(results: TestResults) {
    let converter = TestableConverter()
    
    // Test 12: Non-existent input file
    let nonExistentFile = TestConfig.tempDir.appendingPathComponent("nonexistent.oft")
    let outputFile = TestConfig.tempDir.appendingPathComponent("error_test.eml")
    
    do {
        try converter.runConversion(input: nonExistentFile, output: outputFile)
        results.record(
            test: "Error handling - non-existent file",
            success: false,
            message: "Should have thrown error for non-existent file"
        )
    } catch TestableConverter.ConversionError.fileNotFound {
        results.record(
            test: "Error handling - non-existent file",
            success: true
        )
    } catch {
        results.record(
            test: "Error handling - non-existent file",
            success: false,
            message: "Wrong error type: \(error)"
        )
    }
}

func cleanupTests() {
    // Clean up temporary directory
    try? FileManager.default.removeItem(at: TestConfig.tempDir)
}

// Main test runner
func runAllTests() -> Bool {
    print("🧪 Running macOS App Test Suite")
    print("=" + String(repeating: "=", count: 49))
    
    let results = TestResults()
    
    print("\n📁 Testing Environment Setup...")
    testEnvironmentSetup(results: results)
    
    print("\n🐍 Testing Python Environment...")
    testPythonEnvironment(results: results)
    
    print("\n📂 Testing File Operations...")
    testFileOperations(results: results)
    
    print("\n🔄 Testing Conversion Process...")
    testConversionProcess(results: results)
    
    print("\n⚠️  Testing Error Handling...")
    testErrorHandling(results: results)
    
    cleanupTests()
    results.printSummary()
    
    return results.success
}

// Run tests if this script is executed directly
if CommandLine.argc > 0 && CommandLine.arguments[0].contains("test_app.swift") {
    let success = runAllTests()
    exit(success ? 0 : 1)
}