import Foundation
import AppKit

@MainActor
public final class FirmwareBuildController: ObservableObject {
    @Published public private(set) var isBuilding = false
    @Published public private(set) var status = "Build the current workspace firmware"
    @Published public private(set) var output = ""
    @Published public private(set) var lastLogURL: URL?
    private var process: Process?

    public func buildAndRun(session: EmulatorSession) {
        guard !isBuilding else { return }
        guard let root = workspaceRoot(session: session) else {
            session.showSetupSheet = true
            status = "Choose the project root in Configure Workbench, then build again."
            return
        }
        let script = root.appendingPathComponent("Firmware/renode/build-display.sh")
        guard FileManager.default.fileExists(atPath: script.path) else {
            status = "Workspace must contain Firmware/renode/build-display.sh"
            return
        }
        isBuilding = true
        status = "Building and signing firmware…"
        output = ""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/bash")
        proc.arguments = [script.path]
        proc.currentDirectoryURL = root
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (environment["PATH"] ?? "/usr/bin:/bin")
        proc.environment = environment
        let logURL = root.appendingPathComponent("build/firmware-build.log")
        do {
            try FileManager.default.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
            let log = try FileHandle(forWritingTo: logURL)
            proc.standardOutput = log
            proc.standardError = log
            lastLogURL = logURL
            proc.terminationHandler = { [weak self, weak session] process in
                try? log.close()
                Task { @MainActor in
                    guard let self else { return }
                    self.isBuilding = false
                    self.process = nil
                    self.output = (try? String(contentsOf: logURL)) ?? "Unable to read build log."
                    guard process.terminationStatus == 0, let session else {
                        let lastLine = self.output
                            .split(whereSeparator: { $0.isNewline })
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .last { !$0.isEmpty }
                        self.status = "Build failed (exit " + String(process.terminationStatus) + (lastLine.map { ": " + $0 } ?? "")
                        return
                    }
                    do {
                        let image = root.appendingPathComponent("build/renode-app/app.signed.bin")
                        let manifest = try FirmwareBuildManifest.load(for: image)
                        _ = try manifest.verifiedELF(relativeTo: image)
                        try manifest.verifyConfig(relativeTo: image)
                        let bootloader = root.appendingPathComponent("build/renode-app/mcuboot.elf")
                        guard FileManager.default.fileExists(atPath: bootloader.path) else {
                            throw FirmwareBuildManifest.ManifestError.invalid("Build did not export the matching MCUboot ELF.")
                        }
                        try manifest.verifyMCUboot(bootloader)
                        session.stopSession()
                        session.customWorkspaceURL = root
                        session.updateAsset(kind: .appFirmware, url: image)
                        session.updateAsset(kind: .bootloader, url: bootloader)
                        self.status = "Firmware pair verified; starting Renode…"
                        session.startSession()
                    } catch {
                        self.status = "Build verification failed: " + error.localizedDescription
                    }
                }
            }
            process = proc
            try proc.run()
            Task { @MainActor [weak self] in
                while let self, self.isBuilding {
                    try? await Task.sleep(nanoseconds: 750_000_000)
                    guard self.isBuilding else { break }
                    self.output = (try? String(contentsOf: logURL)) ?? self.output
                }
            }
        } catch {
            isBuilding = false
            process = nil
            status = "Could not start build: \(error.localizedDescription)"
        }
    }

    public func sessionDidStart() {
        status = "Renode running · ready for emulator tests"
    }

    public func cancel() {
        process?.terminate()
    }

    public func workspaceRoot(session: EmulatorSession) -> URL? {
        if let custom = session.customWorkspaceURL {
            let marker = custom.appendingPathComponent("Firmware/renode/build-display.sh")
            return FileManager.default.fileExists(atPath: marker.path) ? custom.standardizedFileURL : nil
        }
        let starts = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath), Bundle.main.bundleURL]
        for start in starts {
            var candidate = start
            for _ in 0..<12 {
                if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Firmware/renode/build-display.sh").path) {
                    return candidate
                }
                candidate.deleteLastPathComponent()
            }
        }
        return nil
    }
}
