import Cocoa
import Foundation
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var dropView: DropView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupWindow()
    }
    
    func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "OFT to EML Converter"
        window.center()
        
        dropView = DropView()
        window.contentView = dropView
        
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class DropView: NSView {
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        registerForDraggedTypes([.fileURL])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.labelColor
        ]
        
        let instructions = """
        Drag and drop OFT files here
        to convert them to EML format
        
        Uses Python extract_msg library
        for reliable conversion
        """
        
        let size = instructions.size(withAttributes: attrs)
        let rect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        
        instructions.draw(in: rect, withAttributes: attrs)
        
        // Draw border
        NSColor.tertiaryLabelColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 20, dy: 20), xRadius: 10, yRadius: 10)
        borderPath.lineWidth = 2
        borderPath.setLineDash([5, 5], count: 2, phase: 0)
        borderPath.stroke()
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [:]) as? [URL] else {
            return []
        }
        
        for item in items {
            if item.pathExtension.lowercased() == "oft" {
                return .copy
            }
        }
        
        return []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [:]) as? [URL] else {
            return false
        }
        
        for item in items {
            if item.pathExtension.lowercased() == "oft" {
                convertOFTToEML(oftURL: item)
            }
        }
        
        return true
    }
    
    func convertOFTToEML(oftURL: URL) {
        let outputURL = oftURL.deletingPathExtension().appendingPathExtension("eml")
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.runPythonConverter(input: oftURL, output: outputURL)
                
                DispatchQueue.main.async {
                    self.showSuccess(message: "Successfully converted:\n\(oftURL.lastPathComponent)\n\nto:\n\(outputURL.lastPathComponent)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError(message: "Failed to convert \(oftURL.lastPathComponent):\n\(error.localizedDescription)")
                }
            }
        }
    }
    
    func runPythonConverter(input: URL, output: URL) throws {
        // Get the app bundle path
        let bundlePath = Bundle.main.bundlePath
        let converterPath = (bundlePath as NSString).appendingPathComponent("Contents/Resources/converter.py")
        
        // Debug: Check if converter exists
        guard FileManager.default.fileExists(atPath: converterPath) else {
            throw ConversionError.conversionFailed("Python converter not found at: \(converterPath)")
        }
        
        // Get the directory where the app bundle is located (not the working directory)
        let appBundleDir = URL(fileURLWithPath: bundlePath).deletingLastPathComponent().path
        let currentDir = FileManager.default.currentDirectoryPath
        let venvPython1 = (appBundleDir as NSString).appendingPathComponent("venv/bin/python")  // venv next to app
        let venvPython2 = (currentDir as NSString).appendingPathComponent("venv/bin/python")     // venv in working dir
        
        // Try venv python first (both locations), then system python  
        let pythonPaths = [
            venvPython1,  // venv next to app bundle
            venvPython2,  // venv in current working directory
            "/usr/bin/python3", 
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/System/Library/Frameworks/Python.framework/Versions/3.12/bin/python3",
            "/System/Library/Frameworks/Python.framework/Versions/3.11/bin/python3"
        ]
        
        var pythonPath: String?
        var debugInfo = "Tried Python paths:\n"
        for path in pythonPaths {
            debugInfo += "- \(path): \(FileManager.default.fileExists(atPath: path) ? "EXISTS" : "NOT FOUND")\n"
            if FileManager.default.fileExists(atPath: path) {
                pythonPath = path
                break
            }
        }
        
        guard let python = pythonPath else {
            throw ConversionError.conversionFailed("Python 3 not found.\n\(debugInfo)")
        }
        
        // Check if input file exists
        guard FileManager.default.fileExists(atPath: input.path) else {
            throw ConversionError.conversionFailed("Input file not found: \(input.path)")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: python)
        process.arguments = [converterPath, input.path, output.path]
        
        // Set the working directory to where the venv and dependencies are
        // Use appBundleDir if that's where we found Python, otherwise currentDir
        let workingDir = python.contains(appBundleDir) ? appBundleDir : currentDir
        process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw ConversionError.conversionFailed("Failed to start Python process: \(error.localizedDescription)")
        }
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorString = String(data: errorData, encoding: .utf8) ?? ""
        
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            var fullError = "Python conversion failed (exit code: \(process.terminationStatus))\n"
            fullError += "Python: \(python)\n"
            fullError += "Converter: \(converterPath)\n"
            fullError += "Working dir: \(currentDir)\n"
            fullError += "Arguments: [\(input.path), \(output.path)]\n"
            
            if !errorString.isEmpty {
                fullError += "STDERR:\n\(errorString)\n"
            }
            if !outputString.isEmpty {
                fullError += "STDOUT:\n\(outputString)\n"
            }
            
            throw ConversionError.conversionFailed(fullError)
        }
        
        // Success - log output
        if !outputString.isEmpty {
            print("Python converter output: \(outputString)")
        }
    }
    
    func showSuccess(message: String) {
        let alert = NSAlert()
        alert.messageText = "Conversion Successful"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Conversion Failed"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum ConversionError: Error {
    case pythonNotFound
    case conversionFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .pythonNotFound:
            return "Python 3 not found. Please install Python 3."
        case .conversionFailed(let message):
            return message
        }
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()