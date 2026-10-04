import SwiftUI

public struct ToolbarControlsView: View {
    @ObservedObject var session: EmulatorSession
    
    public var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(session.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(session.statusMessage)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Divider().frame(height: 16)
            
            // View Mode Picker
            Picker("View Mode", selection: $session.selectedViewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            Divider().frame(height: 16)
            
            // Start / Stop Emulation Toggle Button
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
            
            // Cold Reboot Button
            Button(action: { session.rebootMachine() }) {
                Label("Reboot", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .disabled(!session.isRunning)
            
            // Configure Hardware Button
            Button(action: { session.showSetupSheet = true }) {
                Label("Configure Hardware & OS", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        }
    }
}
