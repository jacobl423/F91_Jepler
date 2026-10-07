import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject private var session = EmulatorSession()
    @StateObject private var firmwareBuild = FirmwareBuildController()
    private let keyboardMonitor = KeyboardMonitor()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: 1. Top Header Bar with Simulation Controls & Tab Selector
            AppTopBarView(session: session, firmwareBuild: firmwareBuild)
            
            Divider()
            
            // MARK: 2. 3-Pane Horizontal Split View
            HSplitView {
                WorkbenchSidebar(title: "Project", edge: .leading,
                                 isExpanded: $session.isSidebarVisible) {
                    ProjectSidebarView(session: session)
                }
                .frame(minWidth: session.isSidebarVisible ? 246 : 60,
                       idealWidth: session.isSidebarVisible ? session.sidebarWidth : 60,
                       maxWidth: session.isSidebarVisible ? 396 : 60)

                // Center Pane: Fluid Dynamic Emulation Workbench
                VStack(spacing: 0) {
                    workbenchPanel
                }
                .frame(minWidth: 320, idealWidth: 540, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                
                WorkbenchSidebar(title: "Terminal", edge: .trailing,
                                 isExpanded: $session.isTerminalVisible) {
                    TerminalView(session: session)
                }
                .frame(minWidth: session.isTerminalVisible ? 276 : 60,
                       idealWidth: session.isTerminalVisible ? 460 : 60,
                       maxWidth: session.isTerminalVisible ? .infinity : 60)

            }
            .animation(.easeInOut(duration: 0.2), value: session.isSidebarVisible)
            .animation(.easeInOut(duration: 0.2), value: session.isTerminalVisible)
            
            // MARK: 3. Error / Warning Banner
            if let err = session.errorMessage {
                HStack(spacing: 8) {
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
        .background(WorkbenchBackdrop())
        .focusedSceneObject(session)
        .focusedSceneObject(session.logStore)
        .focusedSceneObject(session.cpuInspector)
        // MARK: 4. Window Toolbar Controls
        .toolbar {
            // Workbench Configuration Sheet Button
            ToolbarItem(placement: .primaryAction) {
                Button(action: { session.showSetupSheet = true }) {
                    Label("Configure Workbench", systemImage: "gearshape")
                }
                .help("Configure Workbench")
            }
        }
        // MARK: 5. Keyboard Shortcuts (Secondary ⌥⌘S and Tab ⌘1..⌘7)
        .background(
            Group {
                // Secondary Sidebar Toggle Shortcut: ⌥⌘S
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        session.isSidebarVisible.toggle()
                    }
                }) {
                    EmptyView()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                

            }
            .frame(width: 0, height: 0)
            .opacity(0)
        )
        // MARK: 6. Hardware Setup Sheet
        .sheet(isPresented: $session.showSetupSheet) {
            HardwareSetupView(session: session)
        }
        // MARK: 7. Dual Persistence Key Sync & Lifecycle
        .onChange(of: session.isSidebarVisible) { visible in
            UserDefaults.standard.set(visible, forKey: SessionPersistenceKeys.sidebarVisibleAlternate)
        }
        .onAppear {
            UserDefaults.standard.set(session.isSidebarVisible, forKey: SessionPersistenceKeys.sidebarVisibleAlternate)
            setupKeyboardMonitoring()
            session.startSession()
        }
        .onDisappear {
            keyboardMonitor.stop()
            session.stopSession()
        }
    }
    
    // MARK: - Workbench Panel View Mode Router
    @ViewBuilder
    private var workbenchPanel: some View {
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
    @ObservedObject var firmwareBuild: FirmwareBuildController
    
    public init(session: EmulatorSession, firmwareBuild: FirmwareBuildController) {
        self.session = session
        self.firmwareBuild = firmwareBuild
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
            
                // MARK: Build and simulation controls
                HStack(spacing: 6) {
                    Button(action: { firmwareBuild.buildAndRun(session: session) }) {
                        Label(firmwareBuild.isBuilding ? "Building…" : "Build & Run", systemImage: "hammer")
                    }
                    .disabled(firmwareBuild.isBuilding)
                    .help(firmwareBuild.status)
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
                    .workbenchGlass(cornerRadius: 10)
                
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
            HStack(spacing: 8) {
                Text(firmwareBuild.status)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(1)
                    .textSelection(.enabled)
                if let logURL = firmwareBuild.lastLogURL {
                    Button("Build Log") { NSWorkspace.shared.open(logURL) }
                        .font(.system(size: 10))
                }
                if firmwareBuild.isBuilding {
                    Button("Cancel Build") { firmwareBuild.cancel() }
                        .font(.system(size: 10))
                }
                Spacer(minLength: 0)
            }.padding(.horizontal, 10)
            // MARK: Resizable Horizontal Tab Bar (Workbench Modes)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(ViewMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        Button(action: { session.selectedViewMode = mode }) {
                            HStack(spacing: 5) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(mode.rawValue)
                                    .font(.system(size: 11, weight: session.selectedViewMode == mode ? .bold : .medium))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .foregroundStyle(session.selectedViewMode == mode ? Color.accentColor : Color.primary)
                            .workbenchGlass(cornerRadius: 12,
                                            tint: session.selectedViewMode == mode ? .accentColor.opacity(0.2) : nil,
                                            interactive: true)
                        }
                        .buttonStyle(.plain)
                        .help("Switch to \(mode.rawValue) (⌘\(index + 1))")
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity)
            
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 4)
        .workbenchGlass(cornerRadius: 12)
        .padding(4)
    }
}
