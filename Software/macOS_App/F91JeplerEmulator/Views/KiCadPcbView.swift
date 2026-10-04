import SwiftUI
import AppKit

public struct KiCadPcbView: View {
    @ObservedObject var session: EmulatorSession
    @State private var showSideInspectorInCanvas: Bool = false
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar & Main Tab Switcher
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                        Text("KICAD PCB WORKBENCH")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(session.pcbBoard.filename)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        // Board Score Badge
                        if let res = session.pcbValidationResult {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(res.overallScore >= 0.85 ? Color.green : (res.overallScore >= 0.65 ? Color.orange : Color.red))
                                    .frame(width: 6, height: 6)
                                Text("\(res.scorePercentage)%")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    // Quick Load PCB Draft
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.allowedContentTypes = []
                        if panel.runModal() == .OK, let url = panel.url {
                            session.customPCBURL = url
                            session.startSession()
                        }
                    }) {
                        Label("Load Draft...", systemImage: "folder")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    
                    // Re-Validate
                    Button(action: { session.validateActiveBoard() }) {
                        Label("Re-Validate", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }
                
                // 5 Core Mode Tabs
                Picker("Inspector View", selection: $session.pcbInspectorTab) {
                    Text("2D Canvas").tag(0)
                    Text("Validation Engine (\(session.pcbValidationResult?.checks.count ?? 0))").tag(1)
                    Text("Component Inspector").tag(2)
                    Text("Schematic & BOM").tag(3)
                    Text("Revision Diff").tag(4)
                }
                .pickerStyle(.segmented)
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Selected Panel Body
            Group {
                switch session.pcbInspectorTab {
                case 0:
                    // Tab 0: Enhanced 2D Canvas with integrated quick inspector toggle
                    HSplitView {
                        PCBCanvasView(session: session) { selectedFootprint in
                            session.selectedFootprintID = selectedFootprint.reference
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        if showSideInspectorInCanvas {
                            PCBComponentInspectorPanel(session: session)
                                .frame(minWidth: 280, idealWidth: 320, maxWidth: 420)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        Button(action: { showSideInspectorInCanvas.toggle() }) {
                            Label(
                                showSideInspectorInCanvas ? "Hide Inspector" : "Show Inspector",
                                systemImage: "sidebar.trailing"
                            )
                            .font(.system(size: 10))
                        }
                        .buttonStyle(.bordered)
                        .padding(8)
                    }
                    
                case 1:
                    // Tab 1: Full PCB Validation Panel
                    PCBValidationPanel(session: session) { componentRef in
                        session.selectedFootprintID = componentRef
                        session.pcbInspectorTab = 0 // Center and show on canvas
                    }
                    
                case 2:
                    // Tab 2: Dedicated Component Inspector Panel
                    PCBComponentInspectorPanel(session: session)
                    
                case 3:
                    // Tab 3: Schematic & BOM Export Panel
                    PCBSchematicExportPanel(session: session)
                    
                case 4:
                    // Tab 4: Side-by-Side PCB Comparison View
                    PCBComparisonView(session: session)
                    
                default:
                    PCBCanvasView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
