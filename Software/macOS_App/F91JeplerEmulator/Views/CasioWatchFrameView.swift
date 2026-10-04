import SwiftUI
import AppKit

public struct CasioWatchFrameView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Main Watch Bezel Canvas
            GeometryReader { geo in
                let baseWidth: CGFloat = 460
                let baseHeight: CGFloat = 420
                let scale = max(0.4, min(geo.size.width / baseWidth, geo.size.height / baseHeight, 1.2))
                
                ZStack {
                    // Watch Strap Extensions (Top & Bottom)
                    VStack(spacing: 290) {
                        StrapSegmentView(isTop: true)
                        StrapSegmentView(isTop: false)
                    }
                    
                    // Main Resin Watch Case Body (Octagonal F-91W profile)
                    ZStack {
                        // Outer Case Shell
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.16, green: 0.17, blue: 0.19),
                                        Color(red: 0.11, green: 0.12, blue: 0.13),
                                        Color(red: 0.08, green: 0.08, blue: 0.09)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 370, height: 350)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .stroke(Color(white: 0.28), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.85), radius: 18, x: 0, y: 10)
                        
                        // Corner Chamfer Accents (F-91W angled bevels)
                        CasioBezelBevels()
                            .stroke(Color(white: 0.22), lineWidth: 1)
                            .frame(width: 366, height: 346)
                        
                        // Face Inset Faceplate
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(red: 0.07, green: 0.08, blue: 0.1))
                                .frame(width: 295, height: 260)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color(red: 0.72, green: 0.58, blue: 0.2), lineWidth: 2) // Classic gold trim
                                )
                            
                            // Retro Gold & Blue Graphics Lines
                            VStack(spacing: 0) {
                                // Top Header Markings
                                VStack(spacing: 2) {
                                    Text("CASIO")
                                        .font(.system(size: 15, weight: .heavy, design: .default))
                                        .foregroundColor(Color(white: 0.95))
                                        .tracking(2.5)
                                    
                                    HStack(spacing: 8) {
                                        Rectangle().fill(Color(red: 0.1, green: 0.5, blue: 0.9)).frame(width: 30, height: 1.5)
                                        Text("WATER RESIST")
                                            .font(.system(size: 8, weight: .bold, design: .default))
                                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                            .tracking(1.2)
                                        Rectangle().fill(Color(red: 0.1, green: 0.5, blue: 0.9)).frame(width: 30, height: 1.5)
                                    }
                                }
                                .padding(.top, 14)
                                
                                Spacer()
                                
                                // Centered 96×39 OLED Display Bezel Window
                                ZStack {
                                    // Metallic Display Border Inset
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(session.oledTheme.unlitColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(red: 0.35, green: 0.45, blue: 0.4), lineWidth: 1.5)
                                        )
                                        .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 3)
                                    
                                    // Live Emulated Frame Buffer
                                    if let cgImg = session.oledImage {
                                        Image(decorative: cgImg, scale: 1.0)
                                            .resizable()
                                            .interpolation(.none)
                                            .colorMultiply(session.oledTheme.litColor)
                                            .aspectRatio(96.0 / 39.0, contentMode: .fit)
                                            .padding(6)
                                    } else {
                                        VStack(spacing: 2) {
                                            Text("96×39 OLED")
                                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                                .foregroundColor(session.oledTheme.litColor.opacity(0.8))
                                            Text(session.isRunning ? "WAITING FOR ZEPHYR" : "OFFLINE")
                                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(width: 220, height: 98)
                                
                                Spacer()
                                
                                // Bottom Footer Markings
                                VStack(spacing: 2) {
                                    HStack(spacing: 6) {
                                        Rectangle().fill(Color(red: 0.72, green: 0.58, blue: 0.2)).frame(width: 24, height: 1.5)
                                        Text("ALARM CHRONOGRAPH")
                                            .font(.system(size: 8.5, weight: .bold, design: .default))
                                            .foregroundColor(Color(red: 0.72, green: 0.58, blue: 0.2))
                                            .tracking(1.4)
                                        Rectangle().fill(Color(red: 0.72, green: 0.58, blue: 0.2)).frame(width: 24, height: 1.5)
                                    }
                                    
                                    Text("F91_JEPLER · nRF52840")
                                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color(white: 0.6))
                                }
                                .padding(.bottom, 12)
                            }
                            .frame(width: 295, height: 260)
                            
                            // Side Button Action Arrow Labels
                            VStack {
                                HStack {
                                    Text("◄ LIGHT")
                                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(white: 0.8))
                                        .offset(x: 18, y: 72)
                                    Spacer()
                                }
                                HStack {
                                    Text("◄ MODE")
                                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(white: 0.8))
                                        .offset(x: 18, y: 92)
                                    Spacer()
                                    Text("ALARM / 24HR ►")
                                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(white: 0.8))
                                        .offset(x: -14, y: 92)
                                }
                            }
                            .frame(width: 295, height: 260)
                        }
                    }
                    
                    // Physical Push Buttons Overlaid Around Bezel Edge
                    // Button A: Top-Left (LIGHT)
                    CasioPushButton(
                        buttonName: "LIGHT",
                        shortcutKey: "L",
                        altKey: "1",
                        isPressed: session.pressedKeys.contains("1"),
                        isLeft: true,
                        onDown: { session.buttonDown(key: "1") },
                        onUp: { session.buttonUp(key: "1") },
                        onClick: { session.buttonClick(key: "1") }
                    )
                    .offset(x: -198, y: -45)
                    
                    // Button B: Bottom-Left (MODE)
                    CasioPushButton(
                        buttonName: "MODE",
                        shortcutKey: "M",
                        altKey: "2",
                        isPressed: session.pressedKeys.contains("2"),
                        isLeft: true,
                        onDown: { session.buttonDown(key: "2") },
                        onUp: { session.buttonUp(key: "2") },
                        onClick: { session.buttonClick(key: "2") }
                    )
                    .offset(x: -198, y: 55)
                    
                    // Button C: Bottom-Right (ALARM / 24HR TOGGLE)
                    CasioPushButton(
                        buttonName: "TOGGLE",
                        shortcutKey: "A",
                        altKey: "3",
                        isPressed: session.pressedKeys.contains("3"),
                        isLeft: false,
                        onDown: { session.buttonDown(key: "3") },
                        onUp: { session.buttonUp(key: "3") },
                        onClick: { session.buttonClick(key: "3") }
                    )
                    .offset(x: 198, y: 55)
                }
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(minHeight: 330)
            
            // Bottom Workbench Controls Strip (Momentary Clicks, Hold Status, Theme)
            HStack(spacing: 20) {
                // Button A Controls
                ButtonToolbarPill(
                    name: "Button A · Light",
                    hotkey: "L or 1",
                    isPressed: session.pressedKeys.contains("1"),
                    onClick: { session.buttonClick(key: "1") },
                    onToggleHold: {
                        if session.pressedKeys.contains("1") {
                            session.buttonUp(key: "1")
                        } else {
                            session.buttonDown(key: "1")
                        }
                    }
                )
                
                // Button B Controls
                ButtonToolbarPill(
                    name: "Button B · Mode",
                    hotkey: "M or 2",
                    isPressed: session.pressedKeys.contains("2"),
                    onClick: { session.buttonClick(key: "2") },
                    onToggleHold: {
                        if session.pressedKeys.contains("2") {
                            session.buttonUp(key: "2")
                        } else {
                            session.buttonDown(key: "2")
                        }
                    }
                )
                
                // Button C Controls
                ButtonToolbarPill(
                    name: "Button C · Alarm/Toggle",
                    hotkey: "A / Space / 3",
                    isPressed: session.pressedKeys.contains("3"),
                    onClick: { session.buttonClick(key: "3") },
                    onToggleHold: {
                        if session.pressedKeys.contains("3") {
                            session.buttonUp(key: "3")
                        } else {
                            session.buttonDown(key: "3")
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
        .padding(8)
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
                    .frame(width: 32, height: 46)
                    .offset(x: isPressed ? (isLeft ? 4 : -4) : 0) // Visual depression moves inward toward case
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isPressed ? Color.green : Color(white: 0.3), lineWidth: isPressed ? 2 : 1)
                            .offset(x: isPressed ? (isLeft ? 4 : -4) : 0)
                    )
                    .shadow(color: isPressed ? Color.green.opacity(0.5) : Color.black.opacity(0.6), radius: isPressed ? 6 : 4, x: 0, y: 2)
                
                // Push Button Label & Shortcut Badges
                VStack(spacing: 2) {
                    Text(shortcutKey)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(isPressed ? .white : Color(white: 0.15))
                    Text(altKey)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(isPressed ? .white.opacity(0.8) : Color(white: 0.4))
                }
                .offset(x: isPressed ? (isLeft ? 4 : -4) : 0)
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

struct ButtonToolbarPill: View {
    let name: String
    let hotkey: String
    let isPressed: Bool
    let onClick: () -> Void
    let onToggleHold: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPressed ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 9, height: 9)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                Text("[\(hotkey)]")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Button("Click (150ms)") {
                onClick()
            }
            .buttonStyle(.bordered)
            .font(.system(size: 10))
            
            Button(isPressed ? "Release" : "Hold") {
                onToggleHold()
            }
            .buttonStyle(.bordered)
            .tint(isPressed ? .red : .accentColor)
            .font(.system(size: 10))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

struct StrapSegmentView: View {
    let isTop: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.1, green: 0.11, blue: 0.12))
                .frame(width: 170, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(white: 0.22), lineWidth: 1)
                )
        }
    }
}

struct CasioBezelBevels: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let corner: CGFloat = 36
        
        path.move(to: CGPoint(x: corner, y: 0))
        path.addLine(to: CGPoint(x: w - corner, y: 0))
        path.addLine(to: CGPoint(x: w, y: corner))
        path.addLine(to: CGPoint(x: w, y: h - corner))
        path.addLine(to: CGPoint(x: w - corner, y: h))
        path.addLine(to: CGPoint(x: corner, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - corner))
        path.addLine(to: CGPoint(x: 0, y: corner))
        path.closeSubpath()
        
        return path
    }
}
