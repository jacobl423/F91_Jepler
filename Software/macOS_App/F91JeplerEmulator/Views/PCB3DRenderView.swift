import SwiftUI
import AppKit

public struct PCB3DRenderView: View {
    @ObservedObject var session: EmulatorSession
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Control & Status Bar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "cube.transparent.fill")
                        .foregroundColor(.green)
                    Text("KICAD 3D RAYTRACE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("kicad-cli render")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Zoom Controls
                HStack(spacing: 4) {
                    Button(action: { zoomScale = max(0.5, zoomScale * 0.8) }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    
                    Text("\(Int(zoomScale * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .frame(width: 44)
                    
                    Button(action: { zoomScale = min(4.0, zoomScale * 1.25) }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        zoomScale = 1.0
                        panOffset = .zero
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Reset View")
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                Divider().frame(height: 16)
                
                // Re-Render Button
                Button(action: { session.trigger3DRender() }) {
                    if session.isRendering3D {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Label("Re-Render", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(.bordered)
                .font(.system(size: 11))
                .disabled(session.isRendering3D)
                
                // Open in KiCad 3D Viewer
                Button(action: { session.openInKiCad(appType: .pcbEditor) }) {
                    Label("KiCad 3D...", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
                .font(.system(size: 11))
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 3D Image Canvas
            GeometryReader { geo in
                ZStack {
                    // Deep Workbench Canvas Background
                    Color(red: 0.08, green: 0.09, blue: 0.11)
                        .ignoresSafeArea()
                    
                    if let img = session.pcbRender3DImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(zoomScale)
                            .offset(
                                x: panOffset.width + dragStartOffset.width,
                                y: panOffset.height + dragStartOffset.height
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragStartOffset = value.translation
                                    }
                                    .onEnded { value in
                                        panOffset.width += value.translation.width
                                        panOffset.height += value.translation.height
                                        dragStartOffset = .zero
                                    }
                            )
                            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 10)
                    } else if session.isRendering3D {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Rendering 3D PCB in KiCad CLI...")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No 3D render generated yet")
                                .font(.system(size: 13, weight: .bold))
                            Text("Generate a photorealistic 3D raytrace of the board using kicad-cli")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Button("Generate 3D Render") {
                                session.trigger3DRender()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        }
        .onAppear {
            if session.pcbRender3DImage == nil {
                session.trigger3DRender()
            }
        }
    }
}
