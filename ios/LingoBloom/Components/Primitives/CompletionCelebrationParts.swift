// 10x primitive: duolingo/completion-celebration v1
import SwiftUI

/// Emblem-reveal choreography (absorbed level-up-moment): particle burst
/// rings expand, the emblem slot scales in with an overshoot spring, title and
/// subtitle land, then the continue CTA.
@available(iOS 17.0, *)
struct CelebrationEmblemStage<Emblem: View>: View {
    var title: String
    var subtitle: String? = nil
    var config: CompletionCelebrationConfig = CompletionCelebrationConfig()
    var onContinue: () -> Void = {}
    /// Central artwork slot (level number, unit crest, ...).
    @ViewBuilder var emblem: () -> Emblem

    @State private var stage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                staticRays
                    .opacity(stage >= 1 ? 1 : 0)
                    .scaleEffect(stage >= 1 ? 1 : 0.4)
                burstRing(radius: 96, count: 12, size: 8, revealed: stage >= 1)
                burstRing(radius: 140, count: 8, size: 5, revealed: stage >= 2)
                emblem()
                    .frame(width: 132, height: 132)
                    .background(config.emblemRing.opacity(0.15), in: Circle())
                    .overlay(Circle().strokeBorder(config.emblemRing, lineWidth: 5))
                    .scaleEffect(stage >= 1 ? 1 : 0.3)
                    .opacity(stage >= 1 ? 1 : 0)
            }

            Text(title)
                .font(config.headlineFont)
                .foregroundStyle(config.headlineColor)
                .multilineTextAlignment(.center)
                .opacity(stage >= 2 ? 1 : 0)
                .offset(y: stage >= 2 ? 0 : 14)
                .accessibilityAddTraits(.isHeader)

            if let subtitle {
                Text(subtitle)
                    .font(config.subtitleFont)
                    .foregroundStyle(config.subtitleColor)
                    .multilineTextAlignment(.center)
                    .opacity(stage >= 2 ? 1 : 0)
            }

            Spacer()

            DimensionalButton(config.continueTitle, config: config.buttonConfig, action: onContinue)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .opacity(stage >= 3 ? 1 : 0)
                .offset(y: stage >= 3 ? 0 : 20)
                .disabled(stage < 3)
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: stage) { _, new in
            config.hapticsEnabled && new == 1
        }
        .sensoryFeedback(.success, trigger: stage) { _, new in
            config.hapticsEnabled && new == 2
        }
        .task { await run() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(subtitle ?? "")")
    }

    /// Persistent sunburst behind the emblem so the celebration reads even in
    /// a still frame (the particle rings fade out quickly).
    private var staticRays: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(config.burstTint.opacity(0.45))
                    .frame(width: 7, height: 30)
                    .offset(y: -92)
                    .rotationEffect(.degrees(Double(index) * 45 + 22.5))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stage)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Ring of particles that scales out from the emblem and fades.
    private func burstRing(radius: CGFloat, count: Int, size: CGFloat, revealed: Bool) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(config.burstTint)
                    .frame(width: size, height: size)
                    .offset(y: -(revealed ? radius : 20))
                    .rotationEffect(.degrees(Double(index) * 360 / Double(count)))
            }
        }
        .opacity(revealed ? 0 : 1)
        .animation(.easeOut(duration: 0.7), value: revealed)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @MainActor
    private func run() async {
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.3)) { stage = 3 }
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { stage = 1 }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { stage = 2 }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { stage = 3 }
    }
}

/// Reward-reveal choreography (absorbed chest-reveal) framed as a full-screen
/// moment: the chest plays its shake → burst → fly-out sequence, headline and
/// subtitle land, then the continue CTA.
@available(iOS 17.0, *)
struct CelebrationRewardStage<Item: View>: View {
    var title: String
    var subtitle: String? = nil
    var itemLabel: String? = nil
    var config: CompletionCelebrationConfig = CompletionCelebrationConfig()
    var onContinue: () -> Void = {}
    /// The reward content that flies out of the chest.
    @ViewBuilder var item: () -> Item

    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            CelebrationChestReveal(isOpened: true, itemLabel: itemLabel,
                                   config: config,
                                   onRevealed: { withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { revealed = true } },
                                   item: item)
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(config.headlineColor)
                .multilineTextAlignment(.center)
                .opacity(revealed ? 1 : 0)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(config.subtitleColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .opacity(revealed ? 1 : 0)
            }
            Spacer()
            DimensionalButton(config.continueTitle, config: config.buttonConfig, action: onContinue)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 20)
                .disabled(!revealed)
        }
    }
}

/// Chest-open element: shakes with rising urgency, pops with a radial burst
/// and heavy haptic, and the reward item flies out on a spring. Usable
/// standalone inside other layouts.
@available(iOS 17.0, *)
struct CelebrationChestReveal<Item: View>: View {
    /// Flips the sequence: false = idle chest, true = play the open moment.
    var isOpened: Bool
    /// Label shown under the revealed item (e.g. "+50").
    var itemLabel: String? = nil
    var config: CompletionCelebrationConfig = CompletionCelebrationConfig()
    var onRevealed: () -> Void = {}
    /// The reward content that flies out of the chest.
    @ViewBuilder var item: () -> Item

    @State private var phase = Phase.idle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase { case idle, shaking, burst, revealed }

    var body: some View {
        ZStack {
            burstRays
                .opacity(phase == .burst || phase == .revealed ? 1 : 0)
                .scaleEffect(phase == .burst || phase == .revealed ? 1 : 0.3)

            chestArt
                .rotationEffect(.degrees(phase == .shaking ? 4 : 0))
                .scaleEffect(phase == .burst ? 1.15 : 1)
                .animation(phase == .shaking && !reduceMotion
                           ? .easeInOut(duration: 0.09).repeatCount(9, autoreverses: true)
                           : .spring(response: 0.25, dampingFraction: 0.5),
                           value: phase)

            VStack(spacing: 8) {
                item()
                if let itemLabel {
                    Text(itemLabel)
                        .font(config.itemLabelFont)
                        .foregroundStyle(config.itemLabelColor)
                }
            }
            .opacity(phase == .revealed ? 1 : 0)
            .scaleEffect(phase == .revealed ? 1 : 0.2)
            .offset(y: phase == .revealed ? -88 : 0)
        }
        .frame(width: 220, height: 220)
        .onChange(of: isOpened, initial: true) { _, opened in
            if opened { Task { await runSequence() } } else { phase = .idle }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: phase == .burst) { _, new in
            config.hapticsEnabled && new
        }
        .sensoryFeedback(.success, trigger: phase == .revealed) { _, new in
            config.hapticsEnabled && new
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reward chest")
        .accessibilityValue(phase == .revealed ? (itemLabel ?? "Opened") : "Closed")
    }

    /// Chest artwork: the provided glyph, or the built-in drawn chest.
    @ViewBuilder private var chestArt: some View {
        if let glyph = config.chestGlyph {
            glyph
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(config.chestTint)
        } else {
            DrawnChest(bodyTint: config.chestTint,
                       trim: config.chestAccent,
                       isOpen: phase == .revealed)
                .frame(width: 118, height: 96)
        }
    }

    private var burstRays: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(config.burstTint)
                    .frame(width: 6, height: 34)
                    .offset(y: -72)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.3)) { phase = .revealed }
            onRevealed()
            return
        }
        phase = .shaking
        try? await Task.sleep(for: .milliseconds(820))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { phase = .burst }
        try? await Task.sleep(for: .milliseconds(180))
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { phase = .revealed }
        onRevealed()
    }
}

/// Built-in treasure chest drawn with solid shapes: a domed lid that tips
/// open on reveal, a body with a trim band, and a clasp. No gradients or
/// shadows — chunky opaque fills per the set's language.
@available(iOS 17.0, *)
private struct DrawnChest: View {
    var bodyTint: Color
    var trim: Color
    var isOpen: Bool

    var body: some View {
        VStack(spacing: 2) {
            lid
                .rotationEffect(.degrees(isOpen ? -22 : 0), anchor: .bottomLeading)
                .zIndex(1)
            chestBody
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isOpen)
        .accessibilityHidden(true)
    }

    private var lid: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 5,
                                           bottomTrailingRadius: 5, topTrailingRadius: 20,
                                           style: .continuous)
        return shape
            .fill(bodyTint)
            .overlay(alignment: .bottom) {
                Rectangle().fill(trim).frame(height: 6)
                    .clipShape(shape)
            }
            .frame(height: 36)
    }

    private var chestBody: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 14,
                                           bottomTrailingRadius: 14, topTrailingRadius: 5,
                                           style: .continuous)
        return ZStack {
            shape.fill(bodyTint)
            shape.fill(Color.black.opacity(0.12))
            Rectangle().fill(trim).frame(width: 18)
        }
        .clipShape(shape)
        .overlay(alignment: .top) {
            // Clasp straddling the lid seam.
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(trim)
                .frame(width: 26, height: 22)
                .overlay {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 7, height: 7)
                }
                .offset(y: -6)
        }
        .frame(height: 56)
    }
}

#Preview("Emblem reveal") {
    CompletionCelebration(mode: .emblemReveal,
                          title: "Unit 2 complete!",
                          subtitle: "You mastered 24 new words.") {
        Text("2")
            .font(PlayfulTokens.display(64))
            .foregroundStyle(PlayfulTokens.gold)
    }
}
