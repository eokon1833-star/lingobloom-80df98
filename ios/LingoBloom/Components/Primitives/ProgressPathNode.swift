// 10x primitive: duolingo/progress-path v1
import SwiftUI

@available(iOS 17.0, *)
enum ProgressPathNodeState: Equatable {
    case locked
    case active
    case completed
    case legendary
}

/// One circular step node. Reuses `DimensionalButtonStyle` so nodes share the
/// dimensional-button press physics (face collapses onto a solid rim).
@available(iOS 17.0, *)
struct ProgressPathNode: View {
    var state: ProgressPathNodeState
    /// Glyph shown on the node face; defaults are neutral SF Symbols.
    var glyph: Image? = nil
    var isGate: Bool = false
    var config: ProgressPathConfig = ProgressPathConfig()
    var accessibilityTitle: String = "Step"
    var action: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            resolvedGlyph
                .font(.system(size: config.nodeSize * 0.38, weight: .bold))
                .frame(width: config.nodeSize, height: config.nodeSize * 0.72)
        }
        .buttonStyle(DimensionalButtonStyle(config: nodeButtonConfig))
        .disabled(state == .locked)
        .overlay(alignment: .center) {
            if state == .active {
                activeRing
            }
        }
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(accessibilityValue)
    }

    private var resolvedGlyph: some View {
        Group {
            if let glyph {
                glyph
            } else if isGate {
                Image(systemName: state == .locked ? "lock.fill" : "bolt.fill")
            } else {
                switch state {
                case .locked: Image(systemName: "lock.fill")
                case .active: Image(systemName: "star.fill")
                case .completed: Image(systemName: "checkmark")
                case .legendary: Image(systemName: "crown.fill")
                }
            }
        }
    }

    private var nodeButtonConfig: DimensionalButtonConfig {
        var button = DimensionalButtonConfig(
            face: faceColor,
            foreground: state == .locked ? Color(.systemGray) : config.nodeGlyphColor,
            cornerRadius: config.nodeSize,
            rimHeight: config.nodeRimHeight,
            horizontalPadding: 0,
            verticalPadding: 0,
            fillsWidth: false
        )
        if state == .locked {
            button.face = config.lockedFill
            button.rim = config.lockedFill
        }
        return button
    }

    private var faceColor: Color {
        switch state {
        case .locked: config.lockedFill
        case .active: config.activeFill
        case .completed: config.completedFill
        case .legendary: config.legendaryFill
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .locked: "Locked"
        case .active: "Current step"
        case .completed: "Completed"
        case .legendary: "Mastered"
        }
    }

    /// Halo ring drawn around the active node, outside the face.
    private var activeRing: some View {
        Circle()
            .stroke(config.activeFill.opacity(0.35), lineWidth: 6)
            .frame(width: config.nodeSize + 18, height: config.nodeSize + 18)
            .offset(y: -config.nodeRimHeight / 2)
            .allowsHitTesting(false)
    }
}

/// Floating label above the active node, bobbing gently unless Reduce Motion
/// is on. Copy and colors are configurable; the pointer is part of the bubble.
@available(iOS 17.0, *)
struct ProgressPathCallout: View {
    var text: String
    var fill: Color = PlayfulTokens.accent
    var textColor: Color = PlayfulTokens.inkOnAccent
    var font: Font = .system(.caption, design: .rounded, weight: .heavy)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bobbing = false

    var body: some View {
        Text(text)
            .font(font)
            .kerning(0.8)
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .bottom) {
                CalloutPointer()
                    .fill(fill)
                    .frame(width: 14, height: 7)
                    .offset(y: 6.5)
            }
            .offset(y: bobbing ? -4 : 4)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    bobbing = true
                }
            }
            .accessibilityHidden(true)
    }
}

@available(iOS 17.0, *)
private struct CalloutPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview("Node states") {
    VStack(spacing: 28) {
        ProgressPathCallout(text: "START")
        ProgressPathNode(state: .active)
        ProgressPathNode(state: .completed)
        ProgressPathNode(state: .legendary)
        ProgressPathNode(state: .locked)
        ProgressPathNode(state: .locked, isGate: true)
    }
    .padding(32)
}
