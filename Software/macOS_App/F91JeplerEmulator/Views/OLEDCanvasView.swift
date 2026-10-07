import SwiftUI
import CoreGraphics

public struct OLEDCanvasView: View {
    @ObservedObject var displayStore: DisplayStreamStore
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
        self.displayStore = session.displayStore
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Display Toolbar (Theme picker, Grid toggle, Statistics)
            WrappingToolbar {
                Picker("OLED Color Theme", selection: $displayStore.oledTheme) {
                    ForEach(OLEDTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 290)
                
                Toggle("Pixel Grid Mesh", isOn: $displayStore.showPixelGridMesh)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                
                
                // Host ingestion statistics; firmware draw calls are not measured.
                WrappingToolbar(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Host samples/s:")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", displayStore.displayMetrics.fps))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Samples:")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("\(displayStore.displayMetrics.frameCount)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Read/decode:")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f ms", displayStore.displayMetrics.lastFrameLatencyMs))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Lit:")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("\(displayStore.displayMetrics.litPixelCount)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            
            Text("96 × 39 visible pixels · firmware backing height: 40 rows · host samples may repeat")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            // OLED Canvas Frame
            ZStack {
                // Background Glass
                RoundedRectangle(cornerRadius: 8)
                    .fill(displayStore.oledTheme.unlitColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(displayStore.oledTheme.bezelBorderColor, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                
                if let cgImg = displayStore.oledImage {
                    // Crisp integer nearest-neighbor pixel rendering
                    Image(decorative: cgImg, scale: 1.0)
                        .resizable()
                        .interpolation(.none)
                        .colorMultiply(displayStore.oledTheme.litColor)
                        .aspectRatio(96.0 / 39.0, contentMode: .fit)
                        .padding(12)
                        .overlay(
                            Group {
                                if displayStore.showPixelGridMesh {
                                    PixelGridOverlay(width: 96, height: 39)
                                        .padding(12)
                                }
                            }
                        )
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "display")
                            .font(.system(size: 28))
                            .foregroundColor(displayStore.oledTheme.litColor.opacity(0.6))
                        Text("BuyDisplay 0.83\" 96 × 39 White OLED (ER-OLED0.83-1)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(displayStore.oledTheme.litColor)
                        Text(session.isRunning ? "Ingesting I2C Framebuffer (0x3C)..." : "Renode Emulation Inactive")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.1))
    }
}

public struct PixelGridOverlay: View {
    let width: Int
    let height: Int
    
    public var body: some View {
        Canvas { context, size in
            let stepX = size.width / CGFloat(width)
            let stepY = size.height / CGFloat(height)
            
            var path = Path()
            // Subtle horizontal pixel lines
            for y in 0...height {
                let yPos = CGFloat(y) * stepY
                path.move(to: CGPoint(x: 0, y: yPos))
                path.addLine(to: CGPoint(x: size.width, y: yPos))
            }
            // Subtle vertical pixel lines
            for x in 0...width {
                let xPos = CGFloat(x) * stepX
                path.move(to: CGPoint(x: xPos, y: 0))
                path.addLine(to: CGPoint(x: xPos, y: size.height))
            }
            context.stroke(path, with: .color(Color.black.opacity(0.25)), lineWidth: 0.5)
        }
        .drawingGroup()
        .allowsHitTesting(false)
    }
}
