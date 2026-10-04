import SwiftUI
import AppKit

public struct HardwareSetupView: View {
    @ObservedObject var session: EmulatorSession
    @Environment(\.dismiss) private var dismiss
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configure Hardware & OS")
                        .font(.system(size: 16, weight: .bold))
                    Text("Upload custom KiCad PCB files and firmware binaries for emulation.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            // File Upload Pickers
            VStack(spacing: 12) {
                FilePickerRow(
                    title: "KiCad PCB File (.kicad_pcb)",
                    icon: "cpu",
                    selectedURL: session.customPCBURL,
                    allowedExtensions: ["kicad_pcb"],
                    onSelect: { url in session.customPCBURL = url }
                )
                
                FilePickerRow(
                    title: "OS / Application Binary (.bin / .elf)",
                    icon: "doc.bin",
                    selectedURL: session.customAppBinURL,
                    allowedExtensions: ["bin", "elf", "hex"],
                    onSelect: { url in session.customAppBinURL = url }
                )
                
                FilePickerRow(
                    title: "Bootloader Binary (Optional .elf)",
                    icon: "lock.doc",
                    selectedURL: session.customBootloaderURL,
                    allowedExtensions: ["elf"],
                    onSelect: { url in session.customBootloaderURL = url }
                )
            }
            
            Divider()
            
            // Pin Mapping Inspector
            VStack(alignment: .leading, spacing: 10) {
                Text("Pin Mapping Inspector")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Button A (Key 1):")
                            .font(.system(size: 11))
                        TextField("GPIO Pin (e.g. P0.11)", text: $session.pcbBoard.buttonAPin)
                            .textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("Button B (Key 2):")
                            .font(.system(size: 11))
                        TextField("GPIO Pin (e.g. P0.12)", text: $session.pcbBoard.buttonBPin)
                            .textFieldStyle(.roundedBorder)
                    }
                    GridRow {
                        Text("Button C (Key 3):")
                            .font(.system(size: 11))
                        TextField("GPIO Pin (e.g. P0.24)", text: $session.pcbBoard.buttonCPin)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Reset to Defaults") {
                    session.customPCBURL = nil
                    session.customAppBinURL = nil
                    session.customBootloaderURL = nil
                    session.loadEmbeddedDefaults()
                }
                
                Spacer()
                
                Button("Apply & Restart Emulation") {
                    session.startSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 500, height: 440)
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
                    .font(.system(size: 10, design: .monospaced))
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
            .font(.system(size: 11))
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
