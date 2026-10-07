import SwiftUI
import AppKit

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
            content
                .glassEffect(.clear.tint(tint).interactive(interactive), in: shape)
                .overlay(shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.32), .white.opacity(0.04), .white.opacity(0.16)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.75).allowsHitTesting(false))
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
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else {
                DesktopGlassBackdrop()
                Color(nsColor: .windowBackgroundColor).opacity(0.12)
                LinearGradient(colors: [.blue.opacity(0.10), .clear, .teal.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// An inset sidebar with an inward collapse control and an identifying collapsed icon.
struct WorkbenchSidebar<Content: View>: View {
    let title: String
    let edge: HorizontalEdge
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if isExpanded {
                    if edge == .trailing {
                        collapseButton
                        Spacer(minLength: 0)
                    }
                    if edge == .leading { sidebarIcon }
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    if edge == .leading { Spacer(minLength: 0) }
                    if edge == .trailing { sidebarIcon }
                    if edge == .leading { collapseButton }
                } else {
                    collapseButton
                }
            }
            .padding(8)
            .frame(height: 48)

            if isExpanded {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .workbenchGlass(cornerRadius: 22)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private var identitySymbol: String {
        edge == .leading ? "folder" : "terminal"
    }

    private var sidebarIcon: some View {
        Image(systemName: identitySymbol)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 28, height: 32)
            .accessibilityHidden(true)
    }

    private var collapseButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
        } label: {
            Image(systemName: isExpanded
                  ? (edge == .leading ? "sidebar.leading" : "sidebar.trailing")
                  : identitySymbol)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isExpanded ? "Collapse" : "Expand") \(title) sidebar")
        .help("\(isExpanded ? "Collapse" : "Expand") \(title) sidebar")
    }
}

/// Let desktop colors pass through the window beneath the clear glass surfaces.
private struct DesktopGlassBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
