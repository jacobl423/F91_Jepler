import SwiftUI
import AppKit

public struct GDBInspectorView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // GDB Header Controls Bar
            WrappingToolbar {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CORTEX-M4 MCU REGISTER & GDB DEBUGGER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text("Renode GDB Port 3333 • Machine State: \(session.cpuInspector.isPaused ? "PAUSED (Break)" : "RUNNING")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(session.cpuInspector.isPaused ? .orange : .green)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { session.toggleCpuPause() }) {
                        Label(
                            session.cpuInspector.isPaused ? "Resume (F5)" : "Pause (F6)",
                            systemImage: session.cpuInspector.isPaused ? "play.fill" : "pause.fill"
                        )
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundColor(session.cpuInspector.isPaused ? .green : .orange)
                    
                    Button(action: { session.stepInstruction() }) {
                        Label("Step Inst (F10)", systemImage: "arrow.forward.to.line")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .disabled(!session.cpuInspector.isPaused)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            AdaptiveSplitView {
                // Left Sub-Panel: General Purpose Registers R0-R12, SP, LR, PC, xPSR
                VStack(alignment: .leading, spacing: 4) {
                    Text("GENERAL PURPOSE REGISTERS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    
                    List {
                        ForEach(session.cpuInspector.registers) { reg in
                            HStack {
                                Text(reg.name)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(reg.name.contains("PC") ? .yellow : (reg.name.contains("SP") ? .cyan : .primary))
                                    .frame(width: 70, alignment: .leading)
                                
                                Spacer()
                                
                                Text(reg.hexValue)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.5))
                            }
                            .padding(.vertical, 1)
                        }
                    }
                    .listStyle(.inset)
                }
                .frame(minWidth: 220, idealWidth: 260, maxWidth: .infinity, minHeight: 140)
                
                // Right Sub-Panel: Memory & Hex Viewer
                VStack(alignment: .leading, spacing: 6) {
                    WrappingToolbar {
                        Text("MEMORY DUMP / HEX VIEWER")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Addr:")
                            .font(.system(size: 10, design: .monospaced))
                        TextField("Address (hex)", text: $session.cpuInspector.targetMemoryAddressHex)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 90)
                            .padding(2)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                        
                        Button("Inspect") { session.refreshMemoryDump() }
                            .buttonStyle(.borderless)
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    
                    ScrollViewReader { proxy in
                    ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 8) {
                        Section(header: Text("ADDRESS        HEX BYTES                         ASCII").font(.system(size: 9, design: .monospaced)).id("memoryStart")) {
                            ForEach(sampleMemoryRows, id: \.address) { row in
                                HStack(spacing: 12) {
                                    Text(String(format: "0x%08X", row.address))
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    
                                    Text(row.hex)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.7))
                                        .fixedSize()
                                    
                                    Spacer()
                                    
                                    Text(row.ascii)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                        .lineLimit(1)
                        .frame(width: 560, alignment: .leading)
                        .padding(8)
                    }
                    .onAppear { proxy.scrollTo("memoryStart", anchor: .topLeading) }
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private var sampleMemoryRows: [(address: UInt32, hex: String, ascii: String)] {
        let baseAddr: UInt32 = UInt32(session.cpuInspector.targetMemoryAddressHex, radix: 16) ?? 0x20000000
        var rows: [(address: UInt32, hex: String, ascii: String)] = []
        for i in 0..<12 {
            let addr = baseAddr + UInt32(i * 16)
            let hexStr = "20 00 80 00  0C 00 00 00  00 00 00 00  01 00 00 00"
            let asciiStr = "........"
            rows.append((address: addr, hex: hexStr, ascii: asciiStr))
        }
        return rows
    }
}
