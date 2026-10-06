import SwiftUI

/// Wraps toolbar controls without compressing their labels or imposing a pane minimum.
struct WrappingToolbar: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? 1000, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(width: bounds.width, subviews: subviews)
        for (index, placement) in arrangement.placements.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + placement.origin.x,
                                             y: bounds.minY + placement.origin.y),
                                 anchor: .topLeading, proposal: ProposedViewSize(placement.size))
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, placements: [CGRect]) {
        let width = max(0, width)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var placements: [CGRect] = []
        for view in subviews {
            let ideal = view.sizeThatFits(.unspecified)
            let size = view.sizeThatFits(ProposedViewSize(width: min(width, ideal.width), height: nil))
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            placements.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), placements)
    }
}

/// Nested inspectors remain usable when the workbench is narrower than two panes.
struct AdaptiveSplitView<Content: View>: View {
    var minimumHorizontalWidth: CGFloat = 680
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width >= minimumHorizontalWidth {
                HSplitView(content: content)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                VStack(spacing: 8, content: content)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

/// Preserve a useful lower pane, including when the window is shorter than both minima.
enum SplitPaneSizing {
    static func topHeight(preferred: CGFloat, available: CGFloat, minimum: CGFloat,
                          maximum: CGFloat, bottomMinimum: CGFloat = 160, divider: CGFloat = 7) -> CGFloat {
        let usable = max(0, available - divider)
        let lower = min(minimum, usable / 2)
        let upper = max(lower, min(maximum, usable - min(bottomMinimum, usable / 2)))
        return min(max(preferred, lower), upper)
    }
}

struct SplitDragState {
    let startHeight: CGFloat
    var translation: CGFloat
}
