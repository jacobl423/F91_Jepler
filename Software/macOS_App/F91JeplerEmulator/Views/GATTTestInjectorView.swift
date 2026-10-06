import SwiftUI

public struct GATTTestInjectorView: View {
    @ObservedObject var session: EmulatorSession
    
    @State private var notifCategory: NotificationCategory = .sms
    @State private var notifTitle: String = "Alice Smith"
    @State private var notifSubtitle: String = "Message"
    @State private var notifBody: String = "Meeting at 3:00 PM!"
    
    @State private var is24HourClock: Bool = false
    @State private var batteryVoltage: Double = 3.9
    @State private var batteryPct: Double = 85.0
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: Notification GATT Service Injector
                VStack(alignment: .leading, spacing: 12) {
                    WrappingToolbar {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.blue)
                        Text("Notification GATT Service Injector")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("UUID: fa35a2f0-7989-11eb-9439-0242ac130002")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                        GridRow {
                            Text("Category:")
                                .font(.system(size: 11, weight: .medium))
                            Picker("", selection: $notifCategory) {
                                ForEach(NotificationCategory.allCases) { cat in
                                    Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 200)
                        }
                        
                        GridRow {
                            Text("Title / Caller:")
                                .font(.system(size: 11, weight: .medium))
                            TextField("e.g. Alice Smith", text: $notifTitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }
                        
                        GridRow {
                            Text("Subtitle:")
                                .font(.system(size: 11, weight: .medium))
                            TextField("e.g. Work Mobile", text: $notifSubtitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }
                        
                        GridRow {
                            Text("Message Body:")
                                .font(.system(size: 11, weight: .medium))
                            TextField("Notification message text (max 20 bytes streamed)", text: $notifBody)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }
                    }
                    
                    // Hex Serialization Preview
                    let notifPayload = makeNotificationPayload()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GATT Characteristic Payload Preview:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(notifPayload.hexSummary)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.9))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: sendNotification) {
                            Label("Send Notification Payload", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!session.isRunning)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 2: Clock Sync Service Injector
                VStack(alignment: .leading, spacing: 12) {
                    WrappingToolbar {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .foregroundColor(.orange)
                        Text("Clock Sync GATT Service Injector")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("UUID: fa35b2f0-7989-11eb-9439-0242ac130002")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    let clockPayload = ClockSyncPayload(is24Hour: is24HourClock)
                    
                    WrappingToolbar(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Host Epoch:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(clockPayload.timestamp) s")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timezone Offset:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(clockPayload.timezoneOffsetMinutes) min (\(TimeZone.current.identifier))")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        
                        Toggle("24-Hour Mode", isOn: $is24HourClock)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 11))
                        
                        Spacer()
                        
                        Button(action: sendClockSync) {
                            Label("Sync macOS Epoch & Clock", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(!session.isRunning)
                    }
                    
                    // Hex Preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GATT Payload Preview:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(clockPayload.hexSummary)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 3: Virtual Battery & Telemetry Sliders
                VStack(alignment: .leading, spacing: 12) {
                    WrappingToolbar {
                        Image(systemName: "battery.100.bolt")
                            .foregroundColor(.green)
                        Text("Virtual Battery & ADC Telemetry")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("Zephyr BAS (0x180F) / SAADC Channel")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    WrappingToolbar(spacing: 12) {
                        // Battery Gauge
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.15))
                                    .frame(width: 80, height: 40)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 1.5))
                                
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(batteryPct > 20 ? (batteryPct > 50 ? Color.green : Color.yellow) : Color.red)
                                        .frame(width: max(4, 76 * (batteryPct / 100.0)), height: 36)
                                    Spacer(minLength: 0)
                                }
                                .padding(2)
                                
                                Text("\(Int(batteryPct))%")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 2)
                            }
                            
                            if batteryPct <= 15.0 || batteryVoltage < 3.3 {
                                Label("LOW BATTERY", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.red)
                            } else {
                                Text("Normal Level")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Sliders
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Voltage (LiPo / Cell):")
                                        .font(.system(size: 11, weight: .medium))
                                    Spacer()
                                    Text(String(format: "%.2f V", batteryVoltage))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                }
                                Slider(value: $batteryVoltage, in: 3.0...4.2, step: 0.05) { _ in
                                    // Scale percentage to voltage
                                    batteryPct = min(100.0, max(0.0, (batteryVoltage - 3.2) / (4.2 - 3.2) * 100.0))
                                    sendBatteryUpdate()
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("State of Charge (BAS 0x2A19):")
                                        .font(.system(size: 11, weight: .medium))
                                    Spacer()
                                    Text("\(Int(batteryPct)) %")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                }
                                Slider(value: $batteryPct, in: 0...100, step: 1) { _ in
                                    batteryVoltage = 3.2 + (batteryPct / 100.0) * 1.0
                                    sendBatteryUpdate()
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button("Mock 10% Low Battery Warning") {
                            batteryPct = 10.0
                            batteryVoltage = 3.25
                            sendBatteryUpdate()
                        }
                        .font(.system(size: 10))
                        
                        Button("Mock 100% Full Charge") {
                            batteryPct = 100.0
                            batteryVoltage = 4.20
                            sendBatteryUpdate()
                        }
                        .font(.system(size: 10))
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Section 4: GATT Transmission History Log
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent GATT Injections (\(session.gattLogs.count))")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Button("Clear") { session.gattLogs.removeAll() }
                            .font(.system(size: 10))
                    }
                    
                    if session.gattLogs.isEmpty {
                        Text("No GATT injections performed yet. Use controls above to test payloads.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(session.gattLogs.prefix(8)) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(entry.service)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.accentColor)
                                            Text(entry.summary)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        Text(entry.hexData)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.status)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                .padding(6)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }
    
    private func makeNotificationPayload() -> NotificationPayload {
        var p = NotificationPayload()
        p.category = notifCategory
        p.title = notifTitle
        p.subtitle = notifSubtitle
        p.message = notifBody
        return p
    }
    
    private func sendNotification() {
        let payload = makeNotificationPayload()
        session.injectNotification(payload: payload)
    }
    
    private func sendClockSync() {
        let payload = ClockSyncPayload(is24Hour: is24HourClock)
        session.injectClockSync(payload: payload)
    }
    
    private func sendBatteryUpdate() {
        var p = BatteryMockPayload()
        p.percentage = Int(batteryPct)
        p.voltageVolts = batteryVoltage
        session.injectBatteryUpdate(payload: p)
    }
}
