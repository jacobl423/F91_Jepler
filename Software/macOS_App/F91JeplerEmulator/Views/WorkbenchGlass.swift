import SwiftUI

/// Native Liquid Glass on Tahoe, with a material fallback for older supported Macs.
private struct WorkbenchGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var cornerRadius: CGFloat
    var tint: Color?
    var interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if reduceTransparency {
            content
                .background(Color(nsColor: .controlBackgroundColor), in: shape)
                .overlay(shape.strokeBorder(tint ?? Color.primary.opacity(0.12)))
        } else if #available(macOS 26.0, *) {
            content.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .background((tint ?? .clear).opacity(0.15), in: shape)
                .overlay(shape.strokeBorder(Color.white.opacity(0.16)))
        }
    }
}

extension View {
    func workbenchGlass(cornerRadius: CGFloat = 16, tint: Color? = nil,
                        interactive: Bool = false) -> some View {
        modifier(WorkbenchGlass(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }
}

struct WorkbenchBackdrop: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            if !reduceTransparency {
                LinearGradient(colors: [.blue.opacity(0.14), .clear, .teal.opacity(0.1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
