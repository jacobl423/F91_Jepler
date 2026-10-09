import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct HardwareSetupView: View {
    @ObservedObject var session: EmulatorSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var detectedRenode: String?
    @State private var advanced = false
    private let onBuildAndRun: (() -> Void)?

    public init(session: EmulatorSession, onBuildAndRun: (() -> Void)? = nil) {
        self.session = session
        self.onBuildAndRun = onBuildAndRun
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Set up your watch")
                        .font(.system(size: 15, weight: .bold))
                    Text("Select external components before starting the emulator.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    quickStart
                    DisclosureGroup("Advanced settings · custom firmware and development", isExpanded: $advanced) {
                    // Section 1: Toolchain & Execution Environment
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Emulator & Toolchain Paths")
                            .font(.system(size: 12, weight: .bold))
                        
                        // Renode Path Picker
                        HStack {
                            Image(systemName: "terminal.fill")
                                .frame(width: 24)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Renode Executable Path")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(session.customRenodePath ?? RenodeProcessManager.findRenodeExecutable() ?? "Not Found in PATH or /Applications")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(RenodeProcessManager.findRenodeExecutable(customPath: session.customRenodePath) != nil ? .green : .red)
                            }
                            
                            Spacer()
                            
                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    session.customRenodePath = url.path
                                    refreshTools()
                                }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        
                        // Zephyr Workspace Directory Picker
                        HStack {
                            Image(systemName: "folder.fill")
                                .frame(width: 24)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zephyr / Project Root Directory")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(session.customWorkspaceURL?.path ?? "Default Repository Root")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = true
                                panel.canChooseFiles = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    session.customWorkspaceURL = url
                                }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        
                        // Custom .resc Script Picker
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .frame(width: 24)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Renode Simulation Script (.resc)")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(session.customRescURL?.lastPathComponent ?? "Optional — generated from selected firmware")
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    session.customRescURL = url
                                }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    
                    Divider()
                    
                    // Section 2: Firmware & Hardware Files
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. Firmware & Hardware Model Files")
                            .font(.system(size: 12, weight: .bold))
                        
                        FilePickerRow(
                            title: "Application Firmware Binary (.bin / .elf)",
                            icon: "doc.bin.fill",
                            selectedURL: session.customAppBinURL,
                            allowedExtensions: ["bin", "elf", "hex"],
                            onSelect: { url in session.customAppBinURL = url }
                        )
                        
                        FilePickerRow(
                            title: "MCUboot Bootloader Binary (.elf)",
                            icon: "lock.shield.fill",
                            selectedURL: session.customBootloaderURL,
                            allowedExtensions: ["elf"],
                            onSelect: { url in session.customBootloaderURL = url }
                        )
                        
                        FilePickerRow(
                            title: "KiCad PCB Layout File (.kicad_pcb)",
                            icon: "cpu.fill",
                            selectedURL: session.customPCBURL,
                            allowedExtensions: ["kicad_pcb"],
                            onSelect: { url in session.customPCBURL = url }
                        )
                    }
                    
                    Divider()
                    
                    // Section 3: GPIO Pin Mapping Inspector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3. GPIO Button Pin Mapping (Active-Low)")
                            .font(.system(size: 12, weight: .bold))
                        
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                            GridRow {
                                Text("Button A (Light · Key 1):")
                                    .font(.system(size: 11))
                                TextField("Pin (e.g. P0.11)", text: $session.pcbBoard.buttonAPin)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            GridRow {
                                Text("Button B (Mode · Key 2):")
                                    .font(.system(size: 11))
                                TextField("Pin (e.g. P0.12)", text: $session.pcbBoard.buttonBPin)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            GridRow {
                                Text("Button C (Alarm/Toggle · Key 3):")
                                    .font(.system(size: 11))
                                TextField("Pin (e.g. P0.24)", text: $session.pcbBoard.buttonCPin)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                            }
                        }
                    }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            HStack {
                Button("Clear Selections") {
                    session.customRenodePath = nil
                    session.customWorkspaceURL = nil
                    session.customRescURL = nil
                    session.customPCBURL = nil
                    session.customAppBinURL = nil
                    session.customBootloaderURL = nil
                    session.clearAssetSelections()
                    refreshTools()
                }
                .font(.system(size: 11))
                
                Spacer()
                
                if advanced {
                Button("Start Existing Firmware") {
                    session.startSession()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(!session.canStartSession)
                Button("Build & Run") {
                    dismiss()
                    onBuildAndRun?()
                }
                .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(20)
        .frame(width: 600, height: 600)
        .onAppear { refreshTools() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in refreshTools() }
    }

    private func refreshTools() {
        detectedRenode = RenodeProcessManager.findRenodeExecutable(customPath: session.customRenodePath)
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(detectedRenode == nil ? "1. Restore emulator" : "1. Emulator ready", systemImage: detectedRenode == nil ? "arrow.down.circle" : "checkmark.circle.fill")
                .font(.headline)
            if let path = detectedRenode {
                if path == RenodeProcessManager.bundledRenodeExecutable {
                    Text("Renode is built in. No installation or downloads needed.")
                } else {
                    Text("Using your installed Renode.").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("The built-in emulator is missing from this copy. Download a fresh Jepler Dev release, or install Renode separately using the links below.")
                #if arch(arm64)
                Text("Choose the Apple Silicon / arm64 package for this Mac.").font(.caption)
                #else
                Text("Choose the Intel / x86_64 package for this Mac.").font(.caption)
                #endif
                HStack {
                    Link("Download Renode", destination: URL(string: "https://github.com/renode/renode/releases/latest")!)
                    Link("Installation help", destination: URL(string: "https://renode.readthedocs.io/en/latest/introduction/installing.html")!)
                    Button("Check again") { refreshTools() }
                }
                DisclosureGroup("Already use Homebrew?") {
                    Text("Run this in Terminal, then click Check again:").font(.caption)
                    Text("brew install renode/tap/renode").font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    Button("Copy command") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew install renode/tap/renode", forType: .string)
                    }
                }
            }
            Divider()
            Label("2. Select external components", systemImage: "folder").font(.headline)
            Text("PCB layouts, firmware, and bootloaders stay outside the app. Your selections are remembered on this Mac.")
            ForEach([SessionAssetKind.pcb, .appFirmware, .bootloader]) { kind in
                FilePickerRow(title: kind.title, icon: kind.iconName,
                              selectedURL: session.assets[kind]?.fileURL,
                              allowedExtensions: kind.allowedExtensions,
                              onSelect: { session.updateAsset(kind: kind, url: $0) })
            }
            Button("Start Renode") {
                session.startSession()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(detectedRenode == nil || !session.canStartSession || session.isRunning || session.isSessionStarting)

        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct FilePickerRow: View {
    let title: String
    let icon: String
    let selectedURL: URL?
    let allowedExtensions: [String]
    let onSelect: (URL) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                Text(selectedURL?.lastPathComponent ?? "Select an external file")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(selectedURL != nil ? .primary : .secondary)
            }
            
            Spacer()
            
            Button("Choose...") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.allowedContentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }
                if panel.runModal() == .OK, let url = panel.url {
                    onSelect(url)
                }
            }
            .buttonStyle(.bordered)
            .font(.system(size: 10))
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
