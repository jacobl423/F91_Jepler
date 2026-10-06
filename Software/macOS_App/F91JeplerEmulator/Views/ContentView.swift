import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject private var session = EmulatorSession()
    private let keyboardMonitor = KeyboardMonitor()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Resizable Top Bar with ALL Tabs Visible
            AppTopBarView(session: session)
            
            Divider()
            
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
                            minTopHeight: 200,
                            maxTopHeight: 600
                        ) {
                            CasioWatchFrameView(session: session)
                        } bottom: {
                            GATTTestInjectorView(session: session)
                        }
                    }
                }
                .frame(minWidth: 300, idealWidth: 540, maxWidth: .infinity, maxHeight: .infinity)
                
                // Right Panel: Monospaced UART Terminal with ANSI Colors, Filtering, and Inspection
                VStack(spacing: 0) {
                    TerminalView(session: session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 260, idealWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: { session.showSetupSheet = true }) {
                    Label("Configure Workbench", systemImage: "gearshape")
                }
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
    @GestureState private var dragState: SplitDragState?
    @State private var isHoveringDivider = false
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
            let displayedHeight = SplitPaneSizing.topHeight(
                preferred: dragState.map { $0.startHeight + $0.translation } ?? topHeight,
                available: geo.size.height, minimum: minTopHeight, maximum: maxTopHeight
            )
            VStack(spacing: 0) {
                // Top Panel
                top()
                    .frame(height: displayedHeight)
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
                    if inside != isHoveringDivider {
                        isHoveringDivider = inside
                        if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .named("workbenchSplit"))
                        .updating($dragState) { value, state, _ in
                            let start = state?.startHeight ?? SplitPaneSizing.topHeight(
                                preferred: topHeight, available: geo.size.height,
                                minimum: minTopHeight, maximum: maxTopHeight)
                            state = SplitDragState(startHeight: start, translation: value.translation.height)
                        }
                        .onEnded { value in
                            let start = dragState?.startHeight ?? SplitPaneSizing.topHeight(
                                preferred: topHeight, available: geo.size.height,
                                minimum: minTopHeight, maximum: maxTopHeight)
                            topHeight = SplitPaneSizing.topHeight(
                                preferred: start + value.translation.height,
                                available: geo.size.height, minimum: minTopHeight, maximum: maxTopHeight)
                        }
                )
                .onTapGesture(count: 2) {
                    topHeight = SplitPaneSizing.topHeight(
                        preferred: (geo.size.height - 7) / 2, available: geo.size.height,
                        minimum: minTopHeight, maximum: maxTopHeight)
                }
                
                .help("Drag to resize; double-click to balance panes")
                .accessibilityLabel("Workbench pane divider")
                .onDisappear {
                    if isHoveringDivider { NSCursor.pop(); isHoveringDivider = false }
                }
                
                // Bottom Panel
                bottom()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .coordinateSpace(name: "workbenchSplit")
        }
    }
}

public struct AppTopBarView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                // MARK: Leading Section: Sidebar Toggle & App Branding
                HStack(spacing: 8) {
                    Text("Jepler Dev")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                
                    HStack(spacing: 5) {
                        Circle()
                            .fill(session.isRunning ? Color.green : Color.red)
                            .frame(width: 7, height: 7)
                        Text(session.statusMessage)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 220, alignment: .leading)
                    }
                }
                .padding(.leading, 10)
            
                Divider().frame(height: 18)
            
                // MARK: Simulation Controls (Start / Stop / Reboot)
                HStack(spacing: 6) {
                    Button(action: {
                        if session.isRunning {
                            session.stopSession()
                        } else {
                            session.startSession()
                        }
                    }) {
                        Label(session.isRunning ? "Stop" : "Start", systemImage: session.isRunning ? "square.fill" : "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(session.isRunning ? .red : .green)
                    .controlSize(.small)
                
                    Button(action: { session.rebootMachine() }) {
                        Label("Reboot", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!session.isRunning)
                }
            
                Divider().frame(height: 18)
            
                Spacer(minLength: 0)

                // Hotkeys & Settings
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        KeyLegendBadge(key: "1", label: "Light")
                        KeyLegendBadge(key: "2", label: "Mode")
                        KeyLegendBadge(key: "3", label: "Toggle")
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                
                    Button(action: { session.showSetupSheet = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Configure Workbench")
                }
                .padding(.trailing, 12)
            }
            // MARK: Resizable Horizontal Tab Bar (Workbench Modes)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(ViewMode.allCases) { mode in
                        Button(action: { session.selectedViewMode = mode }) {
                            HStack(spacing: 5) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(mode.rawValue)
                                    .font(.system(size: 11, weight: session.selectedViewMode == mode ? .bold : .medium))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                session.selectedViewMode == mode ?
                                    Color.accentColor :
                                    Color(NSColor.controlBackgroundColor)
                            )
                            .foregroundColor(
                                session.selectedViewMode == mode ?
                                    .white :
                                    .primary
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity)
            
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
