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
                        self.status = "Build failed (\(process.terminationStatus)); open build log for details."
                        return
                    }
                    do {
                        let image = root.appendingPathComponent("build/renode-app/app.signed.bin")
                        let manifest = try FirmwareBuildManifest.load(for: image)
                        _ = try manifest.verifiedELF(relativeTo: image)
                        session.stopSession()
                        session.customWorkspaceURL = root
                        session.updateAsset(kind: .appFirmware, url: image)
                        let bootloader = root.appendingPathComponent("bin/mcuboot.elf")
                        if FileManager.default.fileExists(atPath: bootloader.path) {
                            session.updateAsset(kind: .bootloader, url: bootloader)
                        }
                        self.status = "Built \(manifest.sourceRevision.prefix(8))\(manifest.sourceDirty ? " + local edits" : "") · SHA \(manifest.imageSHA256.prefix(12))"
                        session.startSession()
                    } catch {
                        self.status = "Build output verification failed: \(error.localizedDescription)"
                    }
                }
            }
            process = proc
            try proc.run()
        } catch {
            isBuilding = false
            process = nil
            status = "Could not start build: \(error.localizedDescription)"
        }
    }

    public func cancel() {
        process?.terminate()
    }

    public func workspaceRoot(session: EmulatorSession) -> URL? {
        if let custom = session.customWorkspaceURL { return custom }
        let starts = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath), Bundle.main.bundleURL]
        for start in starts {
            var candidate = start
            for _ in 0..<9 {
                if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Firmware/renode/build-display.sh").path) {
                    return candidate
                }
                candidate.deleteLastPathComponent()
            }
        }
        return nil
    }
}
