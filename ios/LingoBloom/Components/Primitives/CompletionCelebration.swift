// 10x primitive: duolingo/completion-celebration v1
import SwiftUI

@available(iOS 17.0, *)
struct CompletionCelebrationStat: Identifiable {
    let id: String
    var label: String
    /// Numeric value counted up on reveal.
    var value: Int
    /// Suffix rendered after the number (e.g. "%", " XP").
    var suffix: String = ""
    var tint: Color = PlayfulTokens.accentSecondary
    var glyph: Image? = nil
}

/// One config for all three celebration modes; unused slots are ignored.
@available(iOS 17.0, *)
struct CompletionCelebrationConfig {
    // Shared choreography
    var headlineFont: Font = .system(.largeTitle, design: .rounded, weight: .heavy)
    var headlineColor: Color = PlayfulTokens.ink
    var subtitleFont: Font = .system(.body, design: .rounded, weight: .semibold)
    var subtitleColor: Color = PlayfulTokens.inkSecondary
    var continueTitle: String = "Continue"
    var buttonConfig: DimensionalButtonConfig = DimensionalButtonConfig()
    /// Delay between each staged reveal step.
    var stagger: Double = 0.45
    var hapticsEnabled: Bool = true
    // Results mode
    var cardFill: Color = PlayfulTokens.surfaceRaised
    var labelFont: Font = .system(.caption, design: .rounded, weight: .heavy)
    var valueFont: Font = .system(.title, design: .rounded, weight: .heavy)
    var bonusFill: Color = PlayfulTokens.gold.opacity(0.18)
    var bonusTint: Color = PlayfulTokens.warning
    // Emblem mode
    var burstTint: Color = PlayfulTokens.gold
    var emblemRing: Color = PlayfulTokens.gold
    // Reward-chest mode
    /// Custom chest artwork slot; `nil` draws the built-in chunky chest.
    var chestGlyph: Image? = nil
    /// Chest body color (warm wood by default).
    var chestTint: Color = Color(red: 0.72, green: 0.45, blue: 0.16)
    /// Trim band, clasp, and lid-edge color.
    var chestAccent: Color = PlayfulTokens.gold
    var itemLabelFont: Font = .system(.headline, design: .rounded, weight: .heavy)
    var itemLabelColor: Color = PlayfulTokens.ink
}

/// Which celebration choreography to play.
@available(iOS 17.0, *)
enum CompletionCelebrationMode {
    /// Staged results ceremony: headline pop, stat cards with count-up
    /// numbers, optional bonus reveal (absorbed lesson-complete-sequence).
    case results(stats: [CompletionCelebrationStat], bonusText: String? = nil)
    /// Particle-burst emblem reveal around the centerpiece slot
    /// (absorbed level-up-moment).
    case emblemReveal
    /// Chest shake-and-pop with the centerpiece flying out
    /// (absorbed chest-reveal). `itemLabel` renders under the reward.
    case rewardReveal(itemLabel: String? = nil)
}

/// Full-screen completion ceremony for any earned moment — finished session,
/// level/milestone up, reward unlock. One component, three choreographies via
/// `mode`; the continue CTA always lands last. Reduce Motion collapses every
/// sequence to a fade.
@available(iOS 17.0, *)
struct CompletionCelebration<Centerpiece: View>: View {
    var mode: CompletionCelebrationMode
    /// Headline copy (e.g. "Session complete!").
    var title: String
    var subtitle: String? = nil
    var config: CompletionCelebrationConfig = CompletionCelebrationConfig()
    var onContinue: () -> Void = {}
    /// Central artwork slot used by `.emblemReveal` (the emblem) and
    /// `.rewardReveal` (the reward item). Ignored by `.results`.
    @ViewBuilder var centerpiece: () -> Centerpiece

    var body: some View {
        switch mode {
        case .results(let stats, let bonusText):
            CelebrationResultsStage(stats: stats, bonusText: bonusText,
                                    title: title, config: config,
                                    onContinue: onContinue)
        case .emblemReveal:
            CelebrationEmblemStage(title: title, subtitle: subtitle,
                                   config: config, onContinue: onContinue,
                                   emblem: centerpiece)
        case .rewardReveal(let itemLabel):
            CelebrationRewardStage(title: title, subtitle: subtitle,
                                   itemLabel: itemLabel, config: config,
                                   onContinue: onContinue, item: centerpiece)
        }
    }
}

@available(iOS 17.0, *)
extension CompletionCelebration where Centerpiece == EmptyView {
    /// Results-mode convenience: no centerpiece slot needed.
    init(mode: CompletionCelebrationMode,
         title: String,
         subtitle: String? = nil,
         config: CompletionCelebrationConfig = CompletionCelebrationConfig(),
         onContinue: @escaping () -> Void = {}) {
        self.init(mode: mode, title: title, subtitle: subtitle, config: config,
                  onContinue: onContinue) { EmptyView() }
    }
}

/// Staged results ceremony: headline pops in, stat cards land one by one with
/// count-up numbers, an optional bonus line reveals, then the continue CTA.
@available(iOS 17.0, *)
fileprivate struct CelebrationResultsStage: View {
    var stats: [CompletionCelebrationStat]
    var bonusText: String?
    var title: String
    var config: CompletionCelebrationConfig
    var onContinue: () -> Void

    @State private var stage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var finalStage: Int { stats.count + (bonusText == nil ? 2 : 3) }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text(title)
                .font(config.headlineFont)
                .foregroundStyle(config.headlineColor)
                .multilineTextAlignment(.center)
                .scaleEffect(stage >= 1 ? 1 : 0.6)
                .opacity(stage >= 1 ? 1 : 0)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    statCard(stat, revealed: stage >= index + 2)
                }
            }
            .padding(.horizontal, 20)

            if let bonusText {
                bonusRow(bonusText)
                    .opacity(stage >= stats.count + 2 ? 1 : 0)
                    .scaleEffect(stage >= stats.count + 2 ? 1 : 0.8)
            }
            Spacer()
            DimensionalButton(config.continueTitle, config: config.buttonConfig, action: onContinue)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .opacity(stage >= finalStage ? 1 : 0)
                .offset(y: stage >= finalStage ? 0 : 24)
                .disabled(stage < finalStage)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: stage) { _, new in
            config.hapticsEnabled && new > 0 && new < finalStage
        }
        .sensoryFeedback(.success, trigger: stage) { _, new in
            config.hapticsEnabled && new == finalStage
        }
        .task { await runSequence() }
    }

    private func statCard(_ stat: CompletionCelebrationStat, revealed: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                if let glyph = stat.glyph {
                    glyph.font(.system(size: 15, weight: .bold))
                }
                CelebrationCountUpText(target: revealed ? stat.value : 0, suffix: stat.suffix,
                                       font: config.valueFont)
            }
            .foregroundStyle(stat.tint)
            Text(stat.label.uppercased())
                .font(config.labelFont)
                .foregroundStyle(.secondary)
                .kerning(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(config.cardFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(stat.tint.opacity(0.5), lineWidth: 2))
        .opacity(revealed ? 1 : 0)
        .scaleEffect(revealed ? 1 : 0.75)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.label): \(stat.value)\(stat.suffix)")
    }

    private func bonusRow(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
        } icon: {
            Image(systemName: "sparkles")
        }
        .foregroundStyle(config.bonusTint)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(config.bonusFill, in: Capsule())
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.3)) { stage = finalStage }
            return
        }
        for step in 1...finalStage {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { stage = step }
            try? await Task.sleep(for: .seconds(config.stagger))
        }
    }
}

/// Number that steps to its target with a numeric-text roll.
@available(iOS 17.0, *)
struct CelebrationCountUpText: View {
    var target: Int
    var suffix: String
    var font: Font
    @State private var shown = 0

    var body: some View {
        Text("\(shown)\(suffix)")
            .font(font)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(shown)))
            .onChange(of: target, initial: true) { _, new in
                Task { @MainActor in
                    guard new != shown else { return }
                    let steps = 12
                    for step in 1...steps {
                        withAnimation(.linear(duration: 0.05)) {
                            shown = new * step / steps
                        }
                        try? await Task.sleep(for: .milliseconds(55))
                    }
                }
            }
    }
}

#Preview("Results ceremony") {
    CompletionCelebration(
        mode: .results(stats: [
            CompletionCelebrationStat(id: "xp", label: "Total XP", value: 24,
                                      tint: PlayfulTokens.warning,
                                      glyph: Image(systemName: "bolt.fill")),
            CompletionCelebrationStat(id: "acc", label: "Accuracy", value: 92, suffix: "%",
                                      tint: PlayfulTokens.accent,
                                      glyph: Image(systemName: "target")),
            CompletionCelebrationStat(id: "time", label: "Speedy", value: 83, suffix: "s",
                                      tint: PlayfulTokens.accentSecondary,
                                      glyph: Image(systemName: "clock.fill")),
        ], bonusText: "Combo bonus +6"),
        title: "Lesson complete!")
}

#Preview("Reward reveal") {
    CompletionCelebration(mode: .rewardReveal(itemLabel: "+50"),
                          title: "Reward unlocked!",
                          subtitle: "You earned a gem bonus.") {
        Image(systemName: "diamond.fill")
            .font(.system(size: 44))
            .foregroundStyle(PlayfulTokens.accentSecondary)
    }
}
