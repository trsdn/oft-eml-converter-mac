import SwiftUI
import UniformTypeIdentifiers

// MARK: - App Entry Point

@main
struct OFTEMLConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 520, height: 460)
        .commands {
            CommandGroup(replacing: .help) {
                Button("OFT-EML Converter on GitHub") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/trsdn/oft-eml-converter-mac")!
                    )
                }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// MARK: - Models

struct ConversionResult: Identifiable, Sendable {
    let id = UUID()
    let inputName: String
    let outputName: String
    let outputPath: String
    let success: Bool
    let error: String?
}

// MARK: - Dependency Management

enum DependencyState: Equatable {
    case checking
    case installing
    case ready
    case noPython
    case failed(String)
}

enum SetupError: LocalizedError {
    case noPython
    case commandFailed(String, String)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .noPython:
            return "Python 3 is required but was not found on this Mac."
        case .commandFailed(let cmd, let detail):
            return "Command failed: \(cmd)\n\(detail)"
        case .verificationFailed:
            return "extract_msg could not be verified after installation."
        }
    }
}

enum DependencyChecker {
    static let supportDir: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return base.appendingPathComponent("OFT-EML-Converter")
    }()

    static let venvDir = supportDir.appendingPathComponent("venv")
    static let venvPython = venvDir.appendingPathComponent("bin/python3").path

    // All paths the converter will search at runtime
    static func pythonSearchPaths() -> [String] {
        let bundlePath = Bundle.main.bundlePath
        let appDir = URL(fileURLWithPath: bundlePath)
            .deletingLastPathComponent().path
        let cwd = FileManager.default.currentDirectoryPath
        return [
            venvPython,
            (appDir as NSString).appendingPathComponent("venv/bin/python"),
            (cwd as NSString).appendingPathComponent("venv/bin/python"),
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
            "/usr/bin/python3",
        ]
    }

    // Find a Python that already has extract_msg
    static func findWorkingPython() -> String? {
        for path in pythonSearchPaths() {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            if testExtractMsg(python: path) { return path }
        }
        return nil
    }

    // Find any working Python (actually runs it, not just file-exists)
    static func findSystemPython() -> String? {
        let paths = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
            "/usr/bin/python3",
        ]
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            if testPythonRuns(path) { return path }
        }
        return nil
    }

    // Verify a Python binary actually executes (catches the CLT stub)
    private static func testPythonRuns(_ python: String) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: python)
        p.arguments = ["--version"]
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        do {
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
        } catch {
            return false
        }
    }

    static func testExtractMsg(python: String) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: python)
        p.arguments = ["-c", "import extract_msg"]
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        do {
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
        } catch {
            return false
        }
    }

    static func install() throws {
        guard let systemPython = findSystemPython() else {
            throw SetupError.noPython
        }

        try FileManager.default.createDirectory(
            at: supportDir, withIntermediateDirectories: true)

        // Create venv — fall back to --without-pip if needed
        if !createVenv(python: systemPython, withPip: true) {
            guard createVenv(python: systemPython, withPip: false) else {
                throw SetupError.commandFailed(
                    "python3 -m venv",
                    "Could not create virtual environment.")
            }
        }

        // Make sure pip is available inside the venv
        try ensurePip()

        // Install extract_msg
        try run(
            venvPython,
            args: ["-m", "pip", "install", "--quiet", "extract_msg"])

        guard testExtractMsg(python: venvPython) else {
            throw SetupError.verificationFailed
        }
    }

    private static func createVenv(python: String, withPip: Bool) -> Bool {
        var args = ["-m", "venv", venvDir.path]
        if !withPip { args.insert("--without-pip", at: 2) }
        do {
            try run(python, args: args)
            return true
        } catch {
            // Clean up partial venv
            try? FileManager.default.removeItem(at: venvDir)
            return false
        }
    }

    private static func ensurePip() throws {
        // Already there?
        if testPythonRuns(venvPython),
            run(venvPython, succeeds: ["-m", "pip", "--version"])
        {
            return
        }

        // Try ensurepip
        if (try? run(venvPython, args: ["-m", "ensurepip", "--default-pip"]))
            != nil
        {
            return
        }

        // Last resort: download get-pip.py
        let getPipURL = URL(string: "https://bootstrap.pypa.io/get-pip.py")!
        let getPipPath = supportDir.appendingPathComponent("get-pip.py")
        let data = try Data(contentsOf: getPipURL)
        try data.write(to: getPipPath)
        defer { try? FileManager.default.removeItem(at: getPipPath) }
        try run(venvPython, args: [getPipPath.path])
    }

    // Run a command, throw on failure
    @discardableResult
    private static func run(_ executable: String, args: [String]) throws
        -> String
    {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let stderr = String(
                data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8) ?? ""
            throw SetupError.commandFailed(
                ([executable] + args).joined(separator: " "), stderr)
        }
        return String(
            data: outPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8) ?? ""
    }

    // Run a command, return success/failure without throwing
    private static func run(
        _ executable: String, succeeds args: [String]
    ) -> Bool {
        (try? run(executable, args: args)) != nil
    }
}

// MARK: - Conversion Engine

enum ConversionError: LocalizedError {
    case pythonNotFound(String)
    case converterNotFound(String)
    case inputNotFound(String)
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .pythonNotFound(let d): return "Python 3 not found.\n\(d)"
        case .converterNotFound(let p): return "Converter not found at: \(p)"
        case .inputNotFound(let p): return "Input file not found: \(p)"
        case .failed(let d): return d
        }
    }
}

enum OFTConverter {
    static func convert(inputPath: String, outputPath: String) throws {
        let bundlePath = Bundle.main.bundlePath
        let converterPath = (bundlePath as NSString)
            .appendingPathComponent("Contents/Resources/converter.py")

        guard FileManager.default.fileExists(atPath: converterPath) else {
            throw ConversionError.converterNotFound(converterPath)
        }

        let python = try findPython(bundlePath: bundlePath)

        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw ConversionError.inputNotFound(inputPath)
        }

        let appBundleDir = URL(fileURLWithPath: bundlePath)
            .deletingLastPathComponent().path
        let currentDir = FileManager.default.currentDirectoryPath
        let workingDir = python.contains(appBundleDir) ? appBundleDir : currentDir

        let process = Process()
        process.executableURL = URL(fileURLWithPath: python)
        process.arguments = [converterPath, inputPath, outputPath]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDir)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let stderr = String(
                data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8) ?? ""
            let stdout = String(
                data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8) ?? ""
            var msg = "Conversion failed (exit \(process.terminationStatus))\n"
            msg += "Python: \(python)\nConverter: \(converterPath)\n"
            msg += "Working dir: \(workingDir)\n"
            if !stderr.isEmpty { msg += "STDERR:\n\(stderr)\n" }
            if !stdout.isEmpty { msg += "STDOUT:\n\(stdout)" }
            throw ConversionError.failed(msg)
        }
    }

    private static func findPython(bundlePath: String) throws -> String {
        let paths = DependencyChecker.pythonSearchPaths()

        var debug = "Tried Python paths:\n"
        for p in paths {
            let exists = FileManager.default.fileExists(atPath: p)
            debug += "  \(p): \(exists ? "EXISTS" : "NOT FOUND")\n"
            if exists { return p }
        }

        throw ConversionError.pythonNotFound(debug)
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var depState: DependencyState = .checking
    @State private var isTargeted = false
    @State private var results: [ConversionResult] = []
    @State private var isConverting = false
    @State private var fileCount = 0

    var body: some View {
        VStack(spacing: 0) {
            switch depState {
            case .checking:
                statusView("Checking dependencies…")
            case .installing:
                statusView("Installing extract_msg…")
            case .ready:
                mainContent
            case .noPython:
                noPythonView
            case .failed(let message):
                errorView(message)
            }
        }
        .frame(minWidth: 520, minHeight: 340)
        .task { await checkDependencies() }
    }

    // MARK: Dependency Setup Views

    private func statusView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private var noPythonView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Python 3 Required")
                .font(.title2.weight(.medium))
            Text(
                "This app needs Python 3 to convert OFT files.\nInstall it, then click Retry."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Download Python") {
                    NSWorkspace.shared.open(
                        URL(string: "https://www.python.org/downloads/macos/")!
                    )
                }
                .buttonStyle(.borderedProminent)
                Button("Retry") {
                    Task { await checkDependencies() }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Setup Required")
                .font(.title2.weight(.medium))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            Button("Retry") {
                Task { await checkDependencies() }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private func checkDependencies() async {
        depState = .checking

        let alreadyReady: Bool = await Task.detached {
            DependencyChecker.findWorkingPython() != nil
        }.value

        if alreadyReady {
            withAnimation { depState = .ready }
            return
        }

        // Check if Python exists at all before trying to install
        let hasPython: Bool = await Task.detached {
            DependencyChecker.findSystemPython() != nil
        }.value

        guard hasPython else {
            withAnimation { depState = .noPython }
            return
        }

        withAnimation { depState = .installing }

        do {
            try await Task.detached {
                try DependencyChecker.install()
            }.value
            withAnimation { depState = .ready }
        } catch SetupError.noPython {
            withAnimation { depState = .noPython }
        } catch {
            withAnimation {
                depState = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            dropZone
                .padding(24)

            if !results.isEmpty {
                Divider()
                resultsList
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
        }
    }

    // MARK: Drop Zone

    private var dropZone: some View {
        VStack(spacing: 14) {
            Spacer()

            if isConverting {
                ProgressView()
                    .controlSize(.large)
                    .padding(.bottom, 4)
                Text(
                    "Converting \(fileCount) file\(fileCount == 1 ? "" : "s")…"
                )
                .font(.title3)
                .foregroundStyle(.secondary)
            } else {
                Image(
                    systemName: isTargeted
                        ? "arrow.down.doc.fill" : "doc.badge.arrow.up"
                )
                .font(.system(size: 44))
                .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                .contentTransition(.symbolEffect(.replace))

                Text("Drop OFT Files Here")
                    .font(.title2.weight(.medium))

                Text("Converts Outlook templates to EML format")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    isTargeted
                        ? Color.accentColor.opacity(0.07) : .clear
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isTargeted
                                ? Color.accentColor
                                : .secondary.opacity(0.25),
                            style: StrokeStyle(
                                lineWidth: 2, dash: [8, 5])
                        )
                }
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: Results List

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Conversions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") {
                    withAnimation { results.removeAll() }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(results) { r in
                        resultRow(r)
                    }
                }
            }
            .frame(maxHeight: 180)
        }
    }

    @ViewBuilder
    private func resultRow(_ r: ConversionResult) -> some View {
        HStack(spacing: 10) {
            Image(
                systemName: r.success
                    ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .foregroundStyle(r.success ? .green : .red)

            VStack(alignment: .leading, spacing: 1) {
                Text(r.inputName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Group {
                    if r.success {
                        Text("→ \(r.outputName)")
                    } else {
                        Text(
                            String(
                                (r.error ?? "Unknown error").prefix(120))
                        )
                        .foregroundStyle(.red.opacity(0.8))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            if r.success {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([
                        URL(fileURLWithPath: r.outputPath)
                    ])
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            .quaternary.opacity(0.4),
            in: RoundedRectangle(cornerRadius: 7))
    }

    // MARK: Drop Handling

    private nonisolated func loadFileURL(from provider: NSItemProvider)
        async -> URL?
    {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.fileURL.identifier
            ) { item, _ in
                if let data = item as? Data,
                    let url = URL(
                        dataRepresentation: data, relativeTo: nil)
                {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        guard !isConverting else { return }

        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await loadFileURL(from: provider),
                    url.pathExtension.lowercased() == "oft"
                {
                    urls.append(url)
                }
            }
            guard !urls.isEmpty else { return }
            await convertFiles(urls)
        }
    }

    private func convertFiles(_ urls: [URL]) async {
        isConverting = true
        fileCount = urls.count

        let filePairs: [(String, String, String, String)] = urls.map {
            url in
            let output = url.deletingPathExtension()
                .appendingPathExtension("eml")
            return (
                url.path, output.path, url.lastPathComponent,
                output.lastPathComponent
            )
        }

        let newResults: [ConversionResult] = await Task.detached {
            filePairs.map {
                (inputPath, outputPath, inputName, outputName) in
                do {
                    try OFTConverter.convert(
                        inputPath: inputPath, outputPath: outputPath)
                    return ConversionResult(
                        inputName: inputName,
                        outputName: outputName,
                        outputPath: outputPath,
                        success: true, error: nil)
                } catch {
                    return ConversionResult(
                        inputName: inputName,
                        outputName: outputName,
                        outputPath: outputPath,
                        success: false,
                        error: error.localizedDescription)
                }
            }
        }.value

        withAnimation(.easeInOut(duration: 0.3)) {
            results.insert(contentsOf: newResults, at: 0)
            isConverting = false
        }
    }
}