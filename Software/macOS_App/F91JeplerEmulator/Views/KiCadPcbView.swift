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
                WrappingToolbar {
                    WrappingToolbar(spacing: 6) {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                        Text("KICAD PCB WORKBENCH")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(session.pcbBoard.filename)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        // Live Watcher Status
                        HStack(spacing: 4) {
                            Circle()
                                .fill(session.isPCBWatcherActive ? Color.green : Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                            Text(session.isPCBWatcherActive ? "Auto-Reload: Active" : "Watcher: Inactive")
                                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(session.isPCBWatcherActive ? .green : .secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(4)
                    }
                    
                    // Quick Action: Open in KiCad
                    Menu {
                        Button(action: { session.openInKiCad(appType: .pcbEditor) }) {
                            Label("Open Board in PCB Editor", systemImage: "square.grid.3x3")
                        }
                        Button(action: { session.openInKiCad(appType: .schematicEditor) }) {
                            Label("Open Schematic Editor", systemImage: "point.filled.topleft.down.curvedto.point.bottomright.up")
                        }
                        Button(action: { session.openInKiCad(appType: .kicadProject) }) {
                            Label("Open KiCad Project", systemImage: "folder.badge.gearshape")
                        }
                        Divider()
                        Button(action: { session.revealActivePCBinFinder() }) {
                            Label("Reveal PCB in Finder", systemImage: "folder")
                        }
                    } label: {
                        Label("Open in KiCad", systemImage: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .menuStyle(.borderlessButton)
                    
                    // Quick Action: Run KiCad DRC
                    Button(action: { session.runKiCadDRC() }) {
                        if session.isRunningDRC {
                            ProgressView().controlSize(.mini)
                        } else {
                            Label("Run DRC", systemImage: "checkmark.shield")
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .disabled(session.isRunningDRC)
                    
                    // Quick Action: Export Gerbers (Zip)
                    Button(action: { session.exportGerberPackage() }) {
                        if session.isExportingGerbers {
                            ProgressView().controlSize(.mini)
                        } else {
                            Label("Export Gerbers", systemImage: "shippingbox")
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .disabled(session.isExportingGerbers)
                    
                    // Re-Validate / Manual Reload
                    Button(action: {
                        if let url = session.activePCBURL {
                            session.reloadPCB(fileURL: url)
                        } else {
                            session.validateActiveBoard()
                        }
                    }) {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }
                
                // Core Mode Tabs
                Picker("Inspector View", selection: $session.pcbInspectorTab) {
                    Text("2D & 3D Canvas").tag(0)
                    Text("KiCad DRC (\(session.kicadDRCReport?.errorCount ?? 0))").tag(1)
                    Text("Rules Engine (\(session.pcbValidationResult?.checks.count ?? 0))").tag(2)
                    Text("Components").tag(3)
                    Text("Schematic & BOM").tag(4)
                    Text("Revision Diff").tag(5)
                }
                .pickerStyle(.menu)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            
            // GPIO Pin Audit Alert Banner (If KiCad nets changed vs emulator GPIOs)
            if let audit = session.pinAuditResult, audit.hasMismatches {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("KiCad Netlist / GPIO Pin Mismatch Detected")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.orange)
                        Text(audit.entries.filter { !$0.isMatching }.map { "\($0.signalName): \($0.detectedPin) (expected \($0.expectedPin))" }.joined(separator: " • "))
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Sync Renode Pins") {
                        session.syncRenodeWithKiCadPins()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .overlay(Rectangle().stroke(Color.orange.opacity(0.3), lineWidth: 1))
            }
            
            // Real-Time Reload Toast Banner
            if let toast = session.pcbReloadToast {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    Spacer()
                    Button("Dismiss") { session.pcbReloadToast = nil }
                        .font(.system(size: 9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.18))
            }
            
            Divider()
            
            // Selected Panel Body
            Group {
                switch session.pcbInspectorTab {
                case 0:
                    // Tab 0: 2D & 3D Canvas
                    AdaptiveSplitView {
                        PCBCanvasView(session: session) { selectedFootprint in
                            session.selectedFootprintID = selectedFootprint.reference
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        if showSideInspectorInCanvas {
                            PCBComponentInspectorPanel(session: session)
                                .frame(minWidth: 260, idealWidth: 320, maxWidth: .infinity, minHeight: 180)
                        }
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        HStack {
                        Spacer()
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
                        .background(.ultraThinMaterial)
                    }
                    
                case 1:
                    // Tab 1: Official KiCad DRC Violation Browser
                    KiCadDRCView(session: session) { _, _ in
                        session.pcbInspectorTab = 0 // Return to canvas
                    }
                    
                case 2:
                    // Tab 2: Internal Architecture Validation Panel
                    PCBValidationPanel(session: session) { componentRef in
                        session.selectedFootprintID = componentRef
                        session.pcbInspectorTab = 0 // Center and show on canvas
                    }
                    
                case 3:
                    // Tab 3: Dedicated Component Inspector Panel
                    PCBComponentInspectorPanel(session: session)
                    
                case 4:
                    // Tab 4: Schematic & BOM Export Panel
                    PCBSchematicExportPanel(session: session)
                    
                case 5:
                    // Tab 5: Side-by-Side PCB Comparison View
                    PCBComparisonView(session: session)
                    
                default:
                    PCBCanvasView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
