import SwiftUI

public struct AutomatedTestRunnerView: View {
    @ObservedObject var session: EmulatorSession
    private let onBuildAndRun: (() -> Void)?
    
    @State private var selectedPresetIndex: Int = 0
    @State private var customSequenceInput: String = "B, B, C, B"
    @State private var customHoldMs: Double = 150
    @State private var customPauseMs: Double = 250
    
    public init(session: EmulatorSession, onBuildAndRun: (() -> Void)? = nil) {
        self.session = session
        self.onBuildAndRun = onBuildAndRun
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: One-Click Boot & Sanity Check
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("One-Click Automated Boot Sanity Check")
                            .font(.system(size: 13, weight: .bold))
                        
                        Spacer()
                        
                        if session.isBootTestRunning {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        
                        Button(action: { session.runBootSanityCheck() }) {
                            Label(session.isBootTestRunning ? "Testing..." : "Run Boot Check", systemImage: "play.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(session.isBootTestRunning || !session.isRunning)
                        .help(session.isRunning ? "Runs a fresh emulator boot and checks UART milestones." : "Use Build & Run first; there is no running firmware to reboot.")
                    }
                    
                    Text("Validates fresh MCUboot handoff and app UART startup markers, including display initialization and BLE advertising startup. This does not test RF, BLE connections, or OTA rollback.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    if !session.isRunning {
                        HStack {
                            Label("No firmware is running yet.", systemImage: "info.circle")
                                .font(.system(size: 11))
                            Spacer()
                            Button("Build & Run") { onBuildAndRun?() }
                                .buttonStyle(.borderedProminent)
                            Button("Configure") { session.showSetupSheet = true }
                                .buttonStyle(.bordered)
                        }
                    }
                    
                    // Checklist of Boot Stages
                    VStack(spacing: 8) {
                        ForEach(session.bootCheckSteps) { step in
                            HStack(spacing: 12) {
                                Group {
                                    switch step.status {
                                    case .pending:
                                        Circle()
                                            .fill(Color.gray.opacity(0.4))
                                            .frame(width: 14, height: 14)
                                    case .running:
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 14, height: 14)
                                    case .passed:
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                    case .failed:
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 14))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(step.name)
                                            .font(.system(size: 11, weight: .semibold))
                                        Spacer()
                                        if step.durationMs > 0 {
                                            Text("\(step.durationMs) ms")
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if !step.detail.isEmpty {
                                        Text(step.detail)
                                            .font(.system(size: 9.5, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                    
                    if let result = session.bootCheckOverallResult {
                        HStack {
                            Image(systemName: result.contains("PASS") ? "checkmark.seal.fill" : "exclamationmark.octagon.fill")
                                .foregroundColor(result.contains("PASS") ? .green : .red)
                            Text(result)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(result.contains("PASS") ? .green : .red)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 2: Automated Button Fuzzing & Sequence Test Runner
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.cyan)
                        Text("Automated Button Fuzzing & Sequence Test Runner")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                    }
                    
                    Text("Automates sequential and rapid button inputs to verify UI state machine stability and catch deadlocks or watchdog timeouts.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    // Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Sequence Preset:")
                            .font(.system(size: 11, weight: .semibold))
                        
                        Picker("", selection: $selectedPresetIndex) {
                            ForEach(0..<SequencePreset.defaultPresets.count, id: \.self) { idx in
                                Text(SequencePreset.defaultPresets[idx].name).tag(idx)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        
                        let currentPreset = SequencePreset.defaultPresets[selectedPresetIndex]
                        Text(currentPreset.description)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button(action: {
                                session.runSequence(preset: currentPreset)
                            }) {
                                Label("Run Preset Sequence", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(!session.isRunning || session.isSequenceRunning)
                            
                            if session.isSequenceRunning {
                                Button("Stop Sequence") {
                                    session.cancelSequence()
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    
                    // Custom Sequence Builder
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Button Sequence Builder:")
                            .font(.system(size: 11, weight: .semibold))
                        
                        HStack(spacing: 10) {
                            Text("Sequence:")
                                .font(.system(size: 11))
                            TextField("e.g. B, B, C, A, B", text: $customSequenceInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        
                        HStack(spacing: 16) {
                            HStack {
                                Text("Hold:")
                                    .font(.system(size: 10))
                                Slider(value: $customHoldMs, in: 50...1000, step: 25)
                                    .frame(width: 80)
                                Text("\(Int(customHoldMs)) ms")
                                    .font(.system(size: 10, design: .monospaced))
                            }
                            
                            HStack {
                                Text("Pause:")
                                    .font(.system(size: 10))
                                Slider(value: $customPauseMs, in: 50...1000, step: 25)
                                    .frame(width: 80)
                                Text("\(Int(customPauseMs)) ms")
                                    .font(.system(size: 10, design: .monospaced))
                            }
                            
                            Spacer()
                            
                            Button(action: runCustomSequence) {
                                Label("Run Custom", systemImage: "play.circle")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!session.isRunning || session.isSequenceRunning)
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    
                    // Sequence Live Execution Monitor
                    if session.isSequenceRunning || !session.sequenceStatusMessage.isEmpty {
                        HStack(spacing: 8) {
                            if session.isSequenceRunning {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                            Text(session.sequenceStatusMessage)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(6)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }
    
    private func runCustomSequence() {
        let tokens = customSequenceInput.components(separatedBy: CharacterSet(charactersIn: ",; "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
        
        var steps: [ButtonSequenceStep] = []
        for token in tokens {
            if token == "A" || token == "1" || token == "LIGHT" {
                steps.append(ButtonSequenceStep(button: .a, holdDurationMs: Int(customHoldMs), pauseAfterMs: Int(customPauseMs)))
            } else if token == "B" || token == "2" || token == "MODE" {
                steps.append(ButtonSequenceStep(button: .b, holdDurationMs: Int(customHoldMs), pauseAfterMs: Int(customPauseMs)))
            } else if token == "C" || token == "3" || token == "TOGGLE" {
                steps.append(ButtonSequenceStep(button: .c, holdDurationMs: Int(customHoldMs), pauseAfterMs: Int(customPauseMs)))
            }
        }
        
        guard !steps.isEmpty else { return }
        let preset = SequencePreset(name: "Custom Sequence", description: customSequenceInput, steps: steps)
        session.runSequence(preset: preset)
    }
}
