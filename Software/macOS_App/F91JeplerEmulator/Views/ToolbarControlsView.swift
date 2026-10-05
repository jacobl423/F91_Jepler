import SwiftUI

public struct ToolbarControlsView: View {
    @ObservedObject var session: EmulatorSession
    
    public var body: some View {
        HStack(spacing: 14) {
            // Renode Status Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(session.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(session.statusMessage)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Divider().frame(height: 16)
            
            // View Mode Selector with Icons
            Picker("Mode", selection: $session.selectedViewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 175)
            
            Divider().frame(height: 16)
            
            // Start / Stop Simulation
            Button(action: {
                if session.isRunning {
                    session.stopSession()
                } else {
                    session.startSession()
                }
            }) {
                Label(
                    session.isRunning ? "Stop" : "Start",
                    systemImage: session.isRunning ? "square.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .foregroundColor(session.isRunning ? .red : .green)
            
            // Cold Reboot Machine Button
            Button(action: { session.rebootMachine() }) {
                Label("Reboot", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .disabled(!session.isRunning)
            
            // Quick Button Hotkey Legend Badge
            HStack(spacing: 4) {
                KeyLegendBadge(key: "1", label: "Light")
                KeyLegendBadge(key: "2", label: "Mode")
                KeyLegendBadge(key: "3", label: "Toggle")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            Divider().frame(height: 16)
            
            // Configure Hardware Sheet
            Button(action: { session.showSetupSheet = true }) {
                Label("Configure Workbench", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        }
    }
}

struct KeyLegendBadge: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 3)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(3)
            Text(label)
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
        }
    }
}
