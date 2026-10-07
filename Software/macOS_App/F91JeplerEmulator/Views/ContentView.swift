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
            WorkbenchSplitView(session: session) {
                WorkbenchSidebar(title: "Project", edge: .leading,
                                 isExpanded: $session.isSidebarVisible) {
                    ProjectSidebarView(session: session)
                }
                .frame(minWidth: session.isSidebarVisible ? 246 : 60,
                       idealWidth: session.isSidebarVisible ? session.sidebarWidth : 60,
                       maxWidth: session.isSidebarVisible ? 396 : 60)

            } center: {
                // Center Pane: Fluid Dynamic Emulation Workbench
                VStack(spacing: 0) {
                    setupFlowCard
                    workbenchPanel
                }
                .frame(minWidth: 320, idealWidth: 540, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                
            } trailing: {
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
        .background(WindowStateRestorer())
        .toolbar {
            ToolbarItem(placement: .navigation) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Jepler Dev")
                        .font(.system(size: 13, weight: .semibold))
                    HStack(spacing: 5) {
                        Circle()
                            .fill(session.isFirmwareReady ? Color.green : Color.secondary)
                            .frame(width: 6, height: 6)
                        Text(session.runtimeLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize()
                .help(session.statusMessage)
                .padding(.trailing, 16)
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Workspace", selection: $session.selectedViewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: session.selectedViewMode.iconName)
                            .foregroundStyle(.secondary)
                        Text(session.selectedViewMode.rawValue)
                            .fontWeight(.medium)
                    }
                    .fixedSize()
                }
                .nativeToolbarControl()
                .help("Choose workspace · ⌘1–⌘7")
            }
            if #available(macOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .automatic)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { firmwareBuild.buildAndRun(session: session) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hammer")
                        Text(firmwareBuild.isBuilding ? "Building…" : "Build & Run")
                    }.fixedSize()
                }
                .nativeToolbarControl()
                .disabled(firmwareBuild.isBuilding || session.isSessionStarting)
                .help(firmwareBuild.status)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    if session.isRunning { session.stopSession() } else { session.startSession() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: session.isRunning ? "stop.fill" : "play.fill")
                        Text(session.isRunning ? "Stop" : "Start")
                    }.fixedSize()
                }
                .nativeToolbarControl()
                .disabled(firmwareBuild.isBuilding || session.isSessionStarting)
                Button { session.rebootMachine() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reboot")
                    }.fixedSize()
                }
                .nativeToolbarControl()
                .disabled(!session.isRunning || session.isHarnessBusy || session.isBootTestRunning || session.isSequenceRunning || firmwareBuild.isBuilding)
            }
            if #available(macOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Configure Workbench", systemImage: "gearshape") { session.showSetupSheet = true }
                    if let logURL = firmwareBuild.lastLogURL {
                        Button("Open Build Log", systemImage: "doc.text") { NSWorkspace.shared.open(logURL) }
                    }
                    if firmwareBuild.isBuilding {
                        Button("Cancel Build", systemImage: "xmark") { firmwareBuild.cancel() }
                    }
                    Divider()
                    Text("Watch buttons: 1 = A · 2 = B · 3 = C")
                } label: {
                    Image(systemName: "gearshape")
                }
                .menuIndicator(.hidden)
                .help("Workbench settings and build options")
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
            HardwareSetupView(session: session) {
                firmwareBuild.buildAndRun(session: session)
            }
        }
        .sheet(isPresented: $session.isRescReviewPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Review Renode Script Before Execution")
                    .font(.headline)
                Text("SHA-256: \(session.rescReviewSHA256 ?? "Unavailable")")
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                Text(".resc scripts execute Renode monitor commands and are executable input. The script bytes below will be executed unchanged. Review every referenced resource before running.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !session.rescReviewReferenceEvidence.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Referenced resources")
                            .font(.caption.weight(.semibold))
                        ForEach(session.rescReviewReferenceEvidence) { evidence in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(evidence.reference)
                                    .font(.system(.caption2, design: .monospaced))
                                Text(evidence.resolvedPath ?? "Not resolved")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(evidence.resolvedPath == nil ? .red : .secondary)
                                if let digest = evidence.sha256 {
                                    Text("SHA-256 \(digest)")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                if let nestedScript = evidence.content {
                                    ScrollView {
                                        Text(nestedScript)
                                            .font(.system(.caption2, design: .monospaced))
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxHeight: 140)
                                    .padding(5)
                                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }
                    }
                }
                ScrollView {
                    Text(session.rescReviewText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    Button("Cancel") { session.isRescReviewPresented = false }
                    Spacer()
                    Button("I Reviewed This Script · Run") { session.approveReviewedRescScript() }
                        .buttonStyle(.borderedProminent)
                        .disabled(session.rescReviewSHA256 == nil)
                }
            }
            .padding(18)
            .frame(minWidth: 650, minHeight: 500)
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
    
    private var setupFlowCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: session.isFirmwareReady ? "checkmark.circle.fill" : "info.circle")
                    .foregroundStyle(session.isFirmwareReady ? .green : Color.secondary)
                Text(session.isRunning || session.isSessionStarting ? session.runtimeLabel : "Start your watch")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if firmwareBuild.isBuilding || session.isSessionStarting {
                    ProgressView().controlSize(.small)
                }
            }

            if firmwareBuild.isBuilding {
                Text(firmwareBuild.status)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                ProgressView()
                DisclosureGroup("Recent build output") {
                    ScrollView {
                        Text(firmwareBuild.output.suffix(2400))
                            .font(.system(size: 9, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 110)
                }
                .font(.system(size: 10))
            } else if session.isSessionStarting {
                Text(session.statusMessage).font(.caption).foregroundStyle(.secondary)
            } else if !session.isRunning {
                if let error = session.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    let buildFailed = firmwareBuild.status.hasPrefix("Build failed") || firmwareBuild.status.hasPrefix("Build verification failed")
                    let sessionNeedsSetup = session.statusMessage == "Firmware is not built yet. Choose Configure & Validate or Build & Run to continue."
                    Text(buildFailed ? firmwareBuild.status : (sessionNeedsSetup ? session.statusMessage : (firmwareBuild.status == "Build the current workspace firmware" ? "1. Configure your project folder  ·  2. Build & Run  ·  3. Send a sample notification" : firmwareBuild.status)))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                if !firmwareBuild.output.isEmpty {
                    DisclosureGroup("Recent build output") {
                        ScrollView {
                            Text(firmwareBuild.output.suffix(2400))
                                .font(.system(size: 9, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 110)
                    }
                    .font(.system(size: 10))
                }
                HStack(spacing: 8) {
                    Button(session.errorMessage == nil ? "Configure & Validate" : "Fix Setup") {
                        session.showSetupSheet = true
                    }
                    .buttonStyle(.bordered)
                    Button(firmwareBuild.status.hasPrefix("Build failed") || firmwareBuild.status.hasPrefix("Build verification failed") ? "Retry Build & Run" : "Build & Run") {
                        firmwareBuild.buildAndRun(session: session)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(firmwareBuild.isBuilding || session.isSessionStarting)
                    if firmwareBuild.lastLogURL != nil {
                        Button("Open Build Log") { openBuildLog() }
                            .buttonStyle(.link)
                    }
                }
            } else {
                HStack {
                    Text(session.isBridgeReady ? "Buttons: 1 = A · 2 = B · 3 = C" : "Waiting for firmware startup. See Terminal for details.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Test notification") {
                        session.injectNotification(payload: NotificationPayload())
                        session.selectedViewMode = .gatt
                    }
                    .disabled(!session.canSendTestRequest)
                    .help("Sends a sample through the emulator’s UART test bridge.")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider() }
        .onChange(of: session.isRunning) { running in
            if running { firmwareBuild.sessionDidStart() }
        }
    }

    private func openBuildLog() {
        if let url = firmwareBuild.lastLogURL { NSWorkspace.shared.open(url) }
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
            AutomatedTestRunnerView(session: session) {
                firmwareBuild.buildAndRun(session: session)
            }
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
                        .fill(Color.clear)
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
