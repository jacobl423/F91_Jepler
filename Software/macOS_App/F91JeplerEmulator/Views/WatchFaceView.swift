import SwiftUI
import AppKit

public struct WatchFaceView: View {
    @ObservedObject var session: EmulatorSession
    
    private var watchIconImage: NSImage? {
        ResourceLoader.image(named: "jepler-icon")
    }
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    private var isCompact: Bool {
        session.selectedViewMode == .split
    }
    
    public var body: some View {
        VStack(spacing: isCompact ? 4 : 12) {
            GeometryReader { geo in
                let baseWidth: CGFloat = 420
                let baseHeight: CGFloat = 380
                
                // Calculate scale factor to fit inside geo size
                let scaleX = geo.size.width / baseWidth
                let scaleY = geo.size.height / baseHeight
                let fitScale = min(scaleX, scaleY)
                let scale = max(0.35, min(fitScale, isCompact ? 0.75 : 1.25))
                
                ZStack {
                    // Background Watch Graphic using jepler-icon with white background card
                    if let nsImg = watchIconImage {
                        Image(nsImage: nsImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 360, height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                            .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 46, style: .continuous)
                            .fill(Color.white)
                            .frame(width: 360, height: 360)
                            .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    
                    // Live OLED Screen Overlay in Screen Area
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.02, green: 0.04, blue: 0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(red: 0.2, green: 0.35, blue: 0.25), lineWidth: 1)
                            )
                        
                        if let cgImg = session.oledImage {
                            Image(decorative: cgImg, scale: 1.0)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(96.0 / 39.0, contentMode: .fit)
                                .padding(4)
                        } else {
                            VStack(spacing: 2) {
                                Text("OLED DISPLAY")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.35, green: 0.75, blue: 0.4))
                                Text(session.isRunning ? "Booting..." : "Off")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(width: 190, height: 82)
                    .offset(y: 4) // Center of watch face screen
                    
                    // Interactive Buttons A, B, C Overlaid on Left and Right Sides
                    WatchButtonOverlayView(
                        label: "1",
                        sublabel: "A",
                        isPressed: session.pressedKeys.contains("1"),
                        onPress: { session.handleKeyDown(key: "1") },
                        onRelease: { session.handleKeyUp(key: "1") }
                    )
                    .offset(x: -188, y: -45)
                    
                    WatchButtonOverlayView(
                        label: "2",
                        sublabel: "B",
                        isPressed: session.pressedKeys.contains("2"),
                        onPress: { session.handleKeyDown(key: "2") },
                        onRelease: { session.handleKeyUp(key: "2") }
                    )
                    .offset(x: -188, y: 55)
                    
                    WatchButtonOverlayView(
                        label: "3",
                        sublabel: "C",
                        isPressed: session.pressedKeys.contains("3"),
                        onPress: { session.handleKeyDown(key: "3") },
                        onRelease: { session.handleKeyUp(key: "3") }
                    )
                    .offset(x: 188, y: 55)
                }
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            
            if !isCompact {
                // Interactive Keyboard Controls Legend
                HStack(spacing: 24) {
                    KeyBadgeView(key: "1", label: "Button A (Top Left)", activePin: session.pcbBoard.buttonAPin, isPressed: session.pressedKeys.contains("1"))
                    KeyBadgeView(key: "2", label: "Button B (Bottom Left)", activePin: session.pcbBoard.buttonBPin, isPressed: session.pressedKeys.contains("2"))
                    KeyBadgeView(key: "3", label: "Button C (Bottom Right)", activePin: session.pcbBoard.buttonCPin, isPressed: session.pressedKeys.contains("3"))
                }
                .padding(.bottom, 8)
            }
        }
        .padding(isCompact ? 4 : 16)
        .background(Color(red: 0.12, green: 0.13, blue: 0.14))
    }
}

struct WatchButtonOverlayView: View {
    let label: String
    let sublabel: String
    let isPressed: Bool
    let onPress: () -> Void
    let onRelease: () -> Void
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPressed ? Color.green : Color(white: 0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isPressed ? Color.green : Color(white: 0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    .frame(width: 28, height: 42)
                
                VStack(spacing: 1) {
                    Text(label)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(isPressed ? .white : Color(white: 0.95))
                    Text(sublabel)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(isPressed ? .white : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

struct KeyBadgeView: View {
    let key: String
    let label: String
    let activePin: String
    let isPressed: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isPressed ? .white : .primary)
                .frame(width: 22, height: 22)
                .background(isPressed ? Color.green : Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.4), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                Text(activePin)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}
