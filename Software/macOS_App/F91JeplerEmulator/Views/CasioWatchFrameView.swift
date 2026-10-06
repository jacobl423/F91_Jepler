import SwiftUI
import AppKit

public struct CasioWatchFrameView: View {
    @ObservedObject var session: EmulatorSession
    
    private var watchIconImage: NSImage? {
        ResourceLoader.image(named: "jepler-icon")
    }
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Main Watch Bezel Canvas
            GeometryReader { geo in
                let baseWidth: CGFloat = 660
                let baseHeight: CGFloat = 380
                let scale = max(0, min(geo.size.width / baseWidth, geo.size.height / baseHeight, 1.25))
                
                ZStack {
                    // Watch Face: PNG of the App Icon with Rounded Corners
                    if let nsImg = watchIconImage {
                        Image(nsImage: nsImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 360, height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 44, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.55), radius: 14, x: 0, y: 7)
                    } else {
                        RoundedRectangle(cornerRadius: 44, style: .continuous)
                            .fill(Color(red: 0.1, green: 0.11, blue: 0.12))
                            .frame(width: 360, height: 360)
                            .overlay(
                                RoundedRectangle(cornerRadius: 44, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.55), radius: 14, x: 0, y: 7)
                    }
                    
                    // Live Emulated 96×39 OLED Display Overlay in Screen Window with Rounded Corners
                    let isDisplayCrossProbed = session.selectedFootprintID.uppercased().contains("J1") || session.selectedFootprintID.uppercased().contains("OLED") || session.selectedFootprintID.uppercased().contains("DISP")
                    
                    CasioLiveOLEDView(
                        displayStore: session.displayStore,
                        isRunning: session.isRunning,
                        isDisplayCrossProbed: isDisplayCrossProbed
                    )
                    .frame(width: 184, height: 86)
                    .offset(x: 0, y: -8)
                    .onTapGesture {
                        session.selectedFootprintID = "J1"
                    }
                    
                    // Cross-Probe States for Buttons
                    let isACrossProbed = session.selectedFootprintID.uppercased().contains("SWITCH1") || session.selectedFootprintID.uppercased().contains("SW1")
                    let isBCrossProbed = session.selectedFootprintID.uppercased().contains("SWITCH2") || session.selectedFootprintID.uppercased().contains("SW2")
                    let isCCrossProbed = session.selectedFootprintID.uppercased().contains("SWITCH3") || session.selectedFootprintID.uppercased().contains("SW3")
                    
                    // Physical Push Buttons Overlaid on Hardware Pusher Stems
                    // Button A: Top-Left (LIGHT)
                    CasioPushButton(
                        buttonName: "LIGHT",
                        shortcutKey: "1",
                        altKey: "",
                        isPressed: session.pressedKeys.contains("1") || isACrossProbed,
                        isLeft: true,
                        onDown: { session.buttonDown(key: "1") },
                        onUp: { session.buttonUp(key: "1") },
                        onClick: {
                            session.selectedFootprintID = "Switch1"
                            session.buttonClick(key: "1")
                        }
                    )
                    .offset(x: -172, y: -46)
                    
                    // Button B: Bottom-Left (MODE)
                    CasioPushButton(
                        buttonName: "MODE",
                        shortcutKey: "2",
                        altKey: "",
                        isPressed: session.pressedKeys.contains("2") || isBCrossProbed,
                        isLeft: true,
                        onDown: { session.buttonDown(key: "2") },
                        onUp: { session.buttonUp(key: "2") },
                        onClick: {
                            session.selectedFootprintID = "Switch2"
                            session.buttonClick(key: "2")
                        }
                    )
                    .offset(x: -172, y: 33)
                    
                    // Button C: Bottom-Right (ALARM / 24HR TOGGLE)
                    CasioPushButton(
                        buttonName: "TOGGLE",
                        shortcutKey: "3",
                        altKey: "",
                        isPressed: session.pressedKeys.contains("3") || isCCrossProbed,
                        isLeft: false,
                        onDown: { session.buttonDown(key: "3") },
                        onUp: { session.buttonUp(key: "3") },
                        onClick: {
                            session.selectedFootprintID = "Switch3"
                            session.buttonClick(key: "3")
                        }
                    )
                    .offset(x: 172, y: 33)
                    
                    // Side Button Controls (Positioned directly adjacent to hardware push pins)
                    // Left Column: Button A (LIGHT) and Button B (MODE)
                    SideButtonControlCard(
                        name: "LIGHT",
                        pin: session.pcbBoard.buttonAPin,
                        hotkey: "1",
                        isPressed: session.pressedKeys.contains("1") || isACrossProbed,
                        isLeft: true,
                        onClick: {
                            session.selectedFootprintID = "Switch1"
                            session.buttonClick(key: "1")
                        },
                        onToggleHold: {
                            session.selectedFootprintID = "Switch1"
                            if session.pressedKeys.contains("1") {
                                session.buttonUp(key: "1")
                            } else {
                                session.buttonDown(key: "1")
                            }
                        }
                    )
                    .offset(x: -250, y: -46)
                    
                    SideButtonControlCard(
                        name: "MODE",
                        pin: session.pcbBoard.buttonBPin,
                        hotkey: "2",
                        isPressed: session.pressedKeys.contains("2") || isBCrossProbed,
                        isLeft: true,
                        onClick: {
                            session.selectedFootprintID = "Switch2"
                            session.buttonClick(key: "2")
                        },
                        onToggleHold: {
                            session.selectedFootprintID = "Switch2"
                            if session.pressedKeys.contains("2") {
                                session.buttonUp(key: "2")
                            } else {
                                session.buttonDown(key: "2")
                            }
                        }
                    )
                    .offset(x: -250, y: 33)
                    
                    // Right Column: Button C (ALARM / 24HR)
                    SideButtonControlCard(
                        name: "ALARM / 24H",
                        pin: session.pcbBoard.buttonCPin,
                        hotkey: "3",
                        isPressed: session.pressedKeys.contains("3") || isCCrossProbed,
                        isLeft: false,
                        onClick: {
                            session.selectedFootprintID = "Switch3"
                            session.buttonClick(key: "3")
                        },
                        onToggleHold: {
                            session.selectedFootprintID = "Switch3"
                            if session.pressedKeys.contains("3") {
                                session.buttonUp(key: "3")
                            } else {
                                session.buttonDown(key: "3")
                            }
                        }
                    )
                    .offset(x: 250, y: 33)
                }
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(minHeight: 0)
        }
        .padding(4)
    }
}

struct CasioPushButton: View {
    let buttonName: String
    let shortcutKey: String
    let altKey: String
    let isPressed: Bool
    let isLeft: Bool
    let onDown: () -> Void
    let onUp: () -> Void
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            ZStack {
                // Outer Metal Push Stem with Tactile Depression Shift
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isPressed ? Color(white: 0.35) : Color(white: 0.75),
                                isPressed ? Color(white: 0.2) : Color(white: 0.5)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 26, height: 38)
                    .offset(x: isPressed ? (isLeft ? 3 : -3) : 0) // Visual depression moves inward toward case
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isPressed ? Color.green : Color(white: 0.3), lineWidth: isPressed ? 2 : 1)
                            .offset(x: isPressed ? (isLeft ? 3 : -3) : 0)
                    )
                    .shadow(color: isPressed ? Color.green.opacity(0.6) : Color.black.opacity(0.6), radius: isPressed ? 6 : 4, x: 0, y: 2)
                
                // Push Button Label & Shortcut Badges
                VStack(spacing: 2) {
                    Text(shortcutKey)
                        .font(.system(size: altKey.isEmpty ? 14 : 12, weight: .black, design: .monospaced))
                        .foregroundColor(isPressed ? .white : Color(white: 0.15))
                    if !altKey.isEmpty {
                        Text(altKey)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(isPressed ? .white.opacity(0.8) : Color(white: 0.4))
                    }
                }
                .offset(x: isPressed ? (isLeft ? 3 : -3) : 0)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { onDown() }
                }
                .onEnded { _ in
                    onUp()
                }
        )
    }
}

struct SideButtonControlCard: View {
    let name: String
    let pin: String
    let hotkey: String
    let isPressed: Bool
    let isLeft: Bool
    let onClick: () -> Void
    let onToggleHold: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                if !isLeft {
                    Image(systemName: "arrowtriangle.backward.fill")
                        .font(.system(size: 7))
                        .foregroundColor(isPressed ? .green : Color(white: 0.5))
                }
                Circle()
                    .fill(isPressed ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 7, height: 7)
                    .shadow(color: isPressed ? Color.green.opacity(0.9) : .clear, radius: 4)
                VStack(alignment: isLeft ? .leading : .trailing, spacing: 1) {
                    Text(name)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isPressed ? .green : .primary)
                    Text("Pin: \(pin)")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                if isLeft {
                    Spacer(minLength: 2)
                    Image(systemName: "arrowtriangle.forward.fill")
                        .font(.system(size: 7))
                        .foregroundColor(isPressed ? .green : Color(white: 0.5))
                }
            }
            Text("Key: \(hotkey)")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: isLeft ? .leading : .trailing)
            HStack(spacing: 4) {
                Button("Click", action: onClick)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.system(size: 9.5, weight: .semibold))
                Button(isPressed ? "Release" : "Hold", action: onToggleHold)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(isPressed ? .red : .accentColor)
                    .font(.system(size: 9.5, weight: .semibold))
            }
        }
        .padding(8)
        .frame(width: 120)
        .workbenchGlass(cornerRadius: 12, tint: isPressed ? .green.opacity(0.2) : nil)
    }
}

struct CasioLiveOLEDView: View {
    @ObservedObject var displayStore: DisplayStreamStore
    let isRunning: Bool
    let isDisplayCrossProbed: Bool
    
    var body: some View {
        ZStack {
            // Display Screen Bezel / Unlit background
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(displayStore.oledTheme.unlitColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isDisplayCrossProbed ? Color.yellow : Color(red: 0.2, green: 0.35, blue: 0.25).opacity(0.8), lineWidth: isDisplayCrossProbed ? 2.5 : 1.5)
                )
                .shadow(color: isDisplayCrossProbed ? Color.yellow.opacity(0.5) : .black.opacity(0.85), radius: isDisplayCrossProbed ? 10 : 6, x: 0, y: 2)
            
            // Live Emulated Frame Buffer
            if let cgImg = displayStore.oledImage {
                Image(decorative: cgImg, scale: 1.0)
                    .resizable()
                    .interpolation(.none)
                    .colorMultiply(displayStore.oledTheme.litColor)
                    .aspectRatio(96.0 / 39.0, contentMode: .fit)
                    .padding(5)
            } else {
                VStack(spacing: 2) {
                    Text("96×39 WHITE OLED")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(displayStore.oledTheme.litColor.opacity(0.85))
                    Text(isRunning ? "ER-OLED0.83-1 READY" : "OFFLINE")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
