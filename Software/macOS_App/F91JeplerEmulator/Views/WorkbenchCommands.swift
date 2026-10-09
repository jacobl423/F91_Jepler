import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Menu actions follow the focused window rather than a separate emulator session.
@MainActor
struct WorkbenchCommands: Commands {
    @FocusedObject private var session: EmulatorSession?
    @FocusedObject private var logs: TerminalLogStore?
    @FocusedObject private var cpu: CPUInspectorModel?

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Configure Workbench…") { session?.showSetupSheet = true }
                .keyboardShortcut(",")
                .disabled(session == nil)
        }
        CommandGroup(after: .newItem) {
            Menu("Open Asset") {
                ForEach(SessionAssetKind.allCases) { kind in
                    Button("\(kind.title)…") { openAsset(kind) }
                }
            }
            .disabled(session == nil)
            Menu("Reload Asset") {
                ForEach(SessionAssetKind.allCases) { kind in
                    Button(kind.title) { session?.reloadAsset(kind: kind) }
                        .disabled(session?.assets[kind]?.filePath == nil)
                }
            }
            Menu("Reveal Asset in Finder") {
                ForEach(SessionAssetKind.allCases) { kind in
                    Button(kind.title) { session?.revealAssetInFinder(kind: kind) }
                        .disabled(session?.assets[kind]?.filePath == nil)
                }
            }
            Divider()
            Button("Clear Component Selections") { session?.clearAssetSelections() }
                .disabled(session == nil)
        }
        CommandGroup(after: .sidebar) {
            Button(session?.isSidebarVisible == true ? "Collapse Project Sidebar" : "Expand Project Sidebar") {
                session?.isSidebarVisible.toggle()
            }
            .keyboardShortcut("0")
            .disabled(session == nil)
            Button(session?.isTerminalVisible == true ? "Collapse Terminal Sidebar" : "Expand Terminal Sidebar") {
                session?.isTerminalVisible.toggle()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(session == nil)
            Divider()
            ForEach(Array(ViewMode.allCases.enumerated()), id: \.element.id) { index, mode in
                Toggle(mode.rawValue, isOn: Binding(
                    get: { session?.selectedViewMode == mode },
                    set: { if $0 { session?.selectedViewMode = mode } }))
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))))
                    .disabled(session == nil)
            }
        }
        CommandMenu("Emulator") {
            Button(session?.isRunning == true ? "Stop Session" : "Start Session") {
                guard let session else { return }
                if session.isRunning { session.stopSession() } else { session.startSession() }
            }
            .keyboardShortcut("r")
            .disabled(session == nil)
            Button("Reboot Machine") { session?.rebootMachine() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!running)
            Divider()
            Button(cpu?.isPaused == true ? "Resume CPU" : "Pause CPU") { session?.toggleCpuPause() }
                .keyboardShortcut("p", modifiers: [.command, .option])
                .disabled(!running)
            Button("Step Instruction") { session?.stepInstruction() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!running || cpu?.isPaused != true)
            Button("Refresh Memory Dump") { session?.refreshMemoryDump() }
                .disabled(!running)
            Divider()
            Menu("Watch Buttons") {
                ForEach(ButtonKey.allCases) { key in
                    Button(key.displayName) { session?.buttonClick(key: key.rawValue) }
                }
            }
            .disabled(!running)
        }
        CommandMenu("Test") {
            Button("Send Default Notification") { session?.injectNotification(payload: NotificationPayload()) }
                .keyboardShortcut("n", modifiers: [.command, .option])
                .disabled(!running)
            Menu("Sync Clock") {
                Button("12-Hour Clock") { session?.injectClockSync(payload: ClockSyncPayload(is24Hour: false)) }
                Button("24-Hour Clock") { session?.injectClockSync(payload: ClockSyncPayload(is24Hour: true)) }
            }
            .disabled(!running)
            Divider()
            Menu("Simulate Battery") {
                Button("Low Battery (10%)") { sendBattery(percentage: 10, voltage: 3.25) }
                Button("Full Charge (100%)") { sendBattery(percentage: 100, voltage: 4.2) }
            }
            .disabled(!running)
            Divider()
            Button("Run Boot Sanity Check") {
                session?.selectedViewMode = .test
                session?.runBootSanityCheck()
            }
            .disabled(!running || session?.isBootTestRunning == true)
            Menu("Run Button Sequence") {
                ForEach(SequencePreset.defaultPresets) { preset in
                    Button(preset.name) {
                        session?.selectedViewMode = .test
                        session?.runSequence(preset: preset)
                    }
                }
            }
            .disabled(!running || session?.isSequenceRunning == true)
            Button("Cancel Button Sequence") { session?.cancelSequence() }
                .disabled(session?.isSequenceRunning != true)
        }
        CommandMenu("PCB") {
            Button("Validate Board") { session?.validateActiveBoard(); session?.selectedViewMode = .pcb }
                .disabled(session?.activePCBURL == nil)
            Button("Audit GPIO Pins") { session?.auditGPIOPins(); session?.selectedViewMode = .pcb }
                .disabled(session?.activePCBURL == nil)
            Divider()
            Menu("Open in KiCad") {
                ForEach(KiCadAppType.allCases) { app in
                    Button(app.rawValue) { session?.openInKiCad(appType: app) }
                }
            }
            .disabled(session?.activePCBURL == nil)
            Button("Render Board in 3D") { session?.selectedViewMode = .pcb; session?.trigger3DRender() }
                .disabled(session?.activePCBURL == nil || session?.isRendering3D == true)
            Button("Run Design Rule Check") { session?.selectedViewMode = .pcb; session?.runKiCadDRC() }
                .disabled(session?.activePCBURL == nil || session?.isRunningDRC == true)
            Button("Export Gerber Package…") { session?.exportGerberPackage() }
                .disabled(session?.activePCBURL == nil || session?.isExportingGerbers == true)
        }
        CommandMenu("Terminal") {
            Button("Show Zephyr UART") { showTerminal(tab: 0) }
                .disabled(session == nil)
            Button("Show Renode Monitor") { showTerminal(tab: 1) }
                .disabled(session == nil)
            Divider()
            Toggle("Auto-Scroll", isOn: Binding(get: { logs?.autoScroll ?? true }, set: { logs?.autoScroll = $0 }))
                .disabled(logs == nil)
            Button("Reset Search and Filters") { logs?.searchText = ""; logs?.selectedCategory = .all }
                .disabled(logs == nil)
            Divider()
            Button("Copy Visible Logs") { logs?.copyVisibleLogs() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(logs?.filteredLines.isEmpty != false)
            Button("Export Visible Logs…") { logs?.exportVisibleLogs() }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(logs?.filteredLines.isEmpty != false)
            Button("Clear Current Log") {
                guard let logs else { return }
                logs.clear(tab: logs.selectedTab)
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .disabled(logs == nil)
        }
    }

    private var running: Bool { session?.isRunning == true }

    private func sendBattery(percentage: Int, voltage: Double) {
        var payload = BatteryMockPayload()
        payload.percentage = percentage
        payload.voltageVolts = voltage
        session?.injectBatteryUpdate(payload: payload)
    }

    private func showTerminal(tab: Int) {
        session?.isTerminalVisible = true
        logs?.selectedTab = tab
    }

    private func openAsset(_ kind: SessionAssetKind) {
        guard let session else { return }
        let panel = NSOpenPanel()
        panel.title = "Open \(kind.title)"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = kind.allowedExtensions.compactMap { UTType(filenameExtension: $0) }
        if panel.runModal() == .OK, let url = panel.url {
            session.updateAsset(kind: kind, url: url)
            session.isSidebarVisible = true
        }
    }
}
