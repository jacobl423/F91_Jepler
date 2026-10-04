import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject private var session = EmulatorSession()
    private let keyboardMonitor = KeyboardMonitor()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Content Body based on selected ViewMode
            HSplitView {
                // Left Panel: Dynamic Workbench View
                VStack(spacing: 0) {
                    switch session.selectedViewMode {
                    case .watch:
                        CasioWatchFrameView(session: session)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .canvas:
                        OLEDCanvasView(session: session)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .gatt:
                        GATTTestInjectorView(session: session)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .test:
                        AutomatedTestRunnerView(session: session)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .pcb:
                        KiCadPcbView(session: session)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .gdb:
                        GDBInspectorView(session: session)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .split:
                        ResizableVSplitView(
                            topHeight: $session.watchPanelHeight,
                            minTopHeight: 280,
                            maxTopHeight: 520
                        ) {
                            CasioWatchFrameView(session: session)
                        } bottom: {
                            GATTTestInjectorView(session: session)
                        }
                    }
                }
                .frame(minWidth: 420, idealWidth: 540, maxWidth: .infinity, maxHeight: .infinity)
                
                // Right Panel: Monospaced UART Terminal with ANSI Colors, Filtering, and Inspection
                VStack(spacing: 0) {
                    TerminalView(session: session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 380, idealWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Error / Warning Banner
            if let err = session.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(err)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Button("Dismiss") { session.errorMessage = nil }
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.18))
            }
        }
        .overlay(
            Group {
                if session.isTargetedForDrop {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 4)
                        .background(Color.accentColor.opacity(0.1))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 36))
                                    .foregroundColor(.accentColor)
                                Text("Drop KiCad PCB or Firmware file to test")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        )
                }
            }
        )
        .onDrop(of: [.fileURL], isTargeted: $session.isTargetedForDrop) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url else { return }
                Task { @MainActor in
                    let ext = url.pathExtension.lowercased()
                    if ext == "kicad_pcb" {
                        session.customPCBURL = url
                        session.startSession()
                    } else if ext == "bin" || ext == "hex" {
                        session.customAppBinURL = url
                        session.startSession()
                    } else if ext == "elf" {
                        session.customBootloaderURL = url
                        session.startSession()
                    } else if ext == "resc" {
                        session.customRescURL = url
                        session.startSession()
                    }
                }
            }
            return true
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ToolbarControlsView(session: session)
            }
        }
        .sheet(isPresented: $session.showSetupSheet) {
            HardwareSetupView(session: session)
        }
        .onAppear {
            setupKeyboardMonitoring()
            session.startSession()
        }
        .onDisappear {
            keyboardMonitor.stop()
            session.stopSession()
        }
    }
    
    private func setupKeyboardMonitoring() {
        keyboardMonitor.onKeyDown = { [weak session] key in
            session?.handleKeyDown(key: key)
        }
        keyboardMonitor.onKeyUp = { [weak session] key in
            session?.handleKeyUp(key: key)
        }
        keyboardMonitor.onBlur = { [weak session] in
            guard let session = session else { return }
            for key in session.pressedKeys {
                session.handleKeyUp(key: key)
            }
        }
        keyboardMonitor.start()
    }
}

public struct ResizableVSplitView<Top: View, Bottom: View>: View {
    @Binding var topHeight: CGFloat
    let minTopHeight: CGFloat
    let maxTopHeight: CGFloat
    let top: () -> Top
    let bottom: () -> Bottom
    
    public init(
        topHeight: Binding<CGFloat>,
        minTopHeight: CGFloat = 110,
        maxTopHeight: CGFloat = 450,
        @ViewBuilder top: @escaping () -> Top,
        @ViewBuilder bottom: @escaping () -> Bottom
    ) {
        self._topHeight = topHeight
        self.minTopHeight = minTopHeight
        self.maxTopHeight = maxTopHeight
        self.top = top
        self.bottom = bottom
    }
    
    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top Panel
                top()
                    .frame(height: max(minTopHeight, min(topHeight, geo.size.height - 120)))
                    .clipped()
                
                // Draggable Splitter Bar with macOS resize cursor
                ZStack {
                    Rectangle()
                        .fill(Color(white: 0.16))
                        .frame(height: 7)
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 32, height: 3.5)
                }
                .contentShape(Rectangle())
                .onHover { inside in
                    if inside {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            let newHeight = topHeight + value.translation.height
                            topHeight = max(minTopHeight, min(newHeight, geo.size.height - 120))
                        }
                )
                .onTapGesture(count: 2) {
                    topHeight = (minTopHeight + maxTopHeight) / 2
                }
                
                // Bottom Panel
                bottom()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
