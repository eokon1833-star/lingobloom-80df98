// 10x primitive: duolingo/progress-path v1
import SwiftUI

/// Colors, glyphs, copy, and geometry for the progress path and its nodes.
/// Defaults come from `PlayfulTokens`; bind the project's theme at the call
/// site or retheme centrally in the tokens.
@available(iOS 17.0, *)
struct ProgressPathConfig {
    var activeFill: Color = PlayfulTokens.accent
    var completedFill: Color = PlayfulTokens.accent
    /// Gold-family by default: legendary means "mastered", not a brand hue.
    var legendaryFill: Color = PlayfulTokens.gold
    var lockedFill: Color = PlayfulTokens.track
    var nodeGlyphColor: Color = PlayfulTokens.inkOnAccent
    var calloutText: String = "START"
    var calloutFill: Color = PlayfulTokens.accent
    var calloutTextColor: Color = PlayfulTokens.inkOnAccent
    /// Section banners are chunky filled cards, echoing the dimensional-button rim.
    var bannerFill: Color = PlayfulTokens.accent
    var bannerTextColor: Color = PlayfulTokens.inkOnAccent
    var bannerFont: Font = .system(.body, design: .rounded, weight: .heavy)
    /// Secondary line under the banner title; `nil` hides it.
    var bannerSubtitleFont: Font = PlayfulTokens.captionFont
    var nodeSize: CGFloat = 72
    var nodeRimHeight: CGFloat = 6
    var verticalSpacing: CGFloat = 26
    /// Peak horizontal displacement of the winding curve.
    var windingAmplitude: CGFloat = 88
    /// Nodes per full left-right-left cycle of the winding curve.
    var windingPeriod: Int = 8
}

@available(iOS 17.0, *)
struct ProgressPathNodeModel: Identifiable {
    let id: String
    var state: ProgressPathNodeState = .locked
    /// Custom glyph for this node; `nil` uses the state's neutral default.
    var glyph: Image? = nil
    /// Jump-ahead gate node: rendered as a gate and reported via `onGateTap`.
    var isGate: Bool = false
    var title: String = "Step"
}

@available(iOS 17.0, *)
struct ProgressPathSection: Identifiable {
    let id: String
    var title: String
    /// Secondary banner line (e.g. "Order food, describe places").
    var subtitle: String? = nil
    var nodes: [ProgressPathNodeModel]
}

/// Scrolling vertical path of step nodes on a winding curve, with
/// section-divider banners between groups and an optional bobbing callout
/// above the active node. Works for any staged journey: lessons, workout
/// programs, course chapters, onboarding quests.
@available(iOS 17.0, *)
struct ProgressPath: View {
    var sections: [ProgressPathSection]
    var config: ProgressPathConfig = ProgressPathConfig()
    var showsCallout: Bool = true
    var onNodeTap: (ProgressPathNodeModel) -> Void = { _ in }
    var onGateTap: (ProgressPathNodeModel) -> Void = { _ in }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: config.verticalSpacing) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { sectionIndex, section in
                    if sectionIndex > 0 {
                        sectionBanner(section)
                            .padding(.vertical, 10)
                    }
                    ForEach(Array(section.nodes.enumerated()), id: \.element.id) { nodeIndex, node in
                        nodeRow(node, index: runningIndex(sectionIndex: sectionIndex) + nodeIndex)
                    }
                }
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
    }

    /// Index of a section's first node in the whole path, so the winding curve
    /// stays continuous across section banners.
    private func runningIndex(sectionIndex: Int) -> Int {
        sections.prefix(sectionIndex).reduce(0) { $0 + $1.nodes.count }
    }

    /// Sine-based winding: nodes sweep left-right-left across the column.
    private func xOffset(for index: Int) -> CGFloat {
        let period = max(config.windingPeriod, 2)
        let angle = Double(index) * 2 * .pi / Double(period)
        return CGFloat(sin(angle)) * config.windingAmplitude
    }

    private func nodeRow(_ node: ProgressPathNodeModel, index: Int) -> some View {
        ProgressPathNode(
            state: node.state,
            glyph: node.glyph,
            isGate: node.isGate,
            config: config,
            accessibilityTitle: node.title
        ) {
            node.isGate ? onGateTap(node) : onNodeTap(node)
        }
        .overlay(alignment: .top) {
            if showsCallout, node.state == .active, !node.isGate {
                ProgressPathCallout(
                    text: config.calloutText,
                    fill: config.calloutFill,
                    textColor: config.calloutTextColor
                )
                .offset(y: -46)
            }
        }
        .padding(.top, showsCallout && node.state == .active && !node.isGate ? 34 : 0)
        .offset(x: xOffset(for: index))
        .zIndex(node.state == .active ? 1 : 0)
    }

    /// Chunky filled banner card with a solid offset rim, echoing the
    /// dimensional-button language.
    private func sectionBanner(_ section: ProgressPathSection) -> some View {
        let shape = RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous)
        return VStack(alignment: .leading, spacing: 2) {
            Text(section.title)
                .font(config.bannerFont)
                .foregroundStyle(config.bannerTextColor)
                .lineLimit(1)
            if let subtitle = section.subtitle {
                Text(subtitle)
                    .font(config.bannerSubtitleFont)
                    .foregroundStyle(config.bannerTextColor.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background {
            shape.fill(config.bannerFill)
                .background {
                    ZStack {
                        shape.fill(config.bannerFill)
                        shape.fill(Color.black.opacity(0.28))
                    }
                    .offset(y: 4)
                }
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Progress path") {
    ProgressPath(sections: [
        ProgressPathSection(id: "u1", title: "Unit 1", nodes: [
            ProgressPathNodeModel(id: "1", state: .legendary, title: "Basics 1"),
            ProgressPathNodeModel(id: "2", state: .completed, title: "Basics 2"),
            ProgressPathNodeModel(id: "3", state: .completed, title: "Basics 3"),
            ProgressPathNodeModel(id: "4", state: .active, title: "Greetings"),
            ProgressPathNodeModel(id: "5", title: "Phrases"),
            ProgressPathNodeModel(id: "6", title: "Review"),
        ]),
        ProgressPathSection(id: "u2", title: "Unit 2", nodes: [
            ProgressPathNodeModel(id: "7", isGate: true, title: "Jump ahead"),
            ProgressPathNodeModel(id: "8", title: "Travel"),
            ProgressPathNodeModel(id: "9", title: "Food"),
        ]),
    ])
}
