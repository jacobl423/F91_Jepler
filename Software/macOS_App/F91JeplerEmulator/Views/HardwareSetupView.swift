import SwiftUI
import AppKit

public struct HardwareSetupView: View {
    @ObservedObject var session: EmulatorSession
    @Environment(\.dismiss) private var dismiss
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Workbench & Hardware Configuration")
                        .font(.system(size: 15, weight: .bold))
                    Text("Configure Renode binary, Zephyr workspace, scripts, and firmware binaries.")
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
                                Text(session.customRescURL?.lastPathComponent ?? "Default (test_boot.resc / f91_jepler.resc)")
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
            .frame(maxHeight: 380)
            
            Divider()
            
            HStack {
                Button("Reset Defaults") {
                    session.customRenodePath = nil
                    session.customWorkspaceURL = nil
                    session.customRescURL = nil
                    session.customPCBURL = nil
                    session.customAppBinURL = nil
                    session.customBootloaderURL = nil
                    session.loadEmbeddedDefaults()
                }
                .font(.system(size: 11))
                
                Spacer()
                
                Button("Apply & Restart Emulation") {
                    session.startSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 540, height: 500)
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
                Text(selectedURL?.lastPathComponent ?? "Default embedded resource")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(selectedURL != nil ? .primary : .secondary)
            }
            
            Spacer()
            
            Button("Choose...") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.allowedContentTypes = []
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
