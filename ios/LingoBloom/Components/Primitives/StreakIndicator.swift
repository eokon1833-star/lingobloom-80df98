// 10x primitive: duolingo/streak-indicator v1
import SwiftUI

/// One escalation tier: at or above `threshold` days the counter takes this
/// tint, scale, and particle intensity.
@available(iOS 17.0, *)
struct StreakTier {
    var threshold: Int
    var tint: Color
    var scale: CGFloat = 1
    /// 0 = no sparks, 1 = full spark shower.
    var particleIntensity: Double = 0
}

@available(iOS 17.0, *)
struct StreakIndicatorConfig {
    /// Glyph slot for the streak mark; neutral flame symbol by default.
    var glyph: Image = Image(systemName: "flame.fill")
    var glyphSize: CGFloat = 24
    var inactiveTint: Color = PlayfulTokens.inkDisabled
    var countFont: Font = .system(.title2, design: .rounded, weight: .heavy)
    var countColor: Color = PlayfulTokens.ink
    var tiers: [StreakTier] = [
        StreakTier(threshold: 1, tint: PlayfulTokens.warning, scale: 1, particleIntensity: 0),
        StreakTier(threshold: 7, tint: PlayfulTokens.warning, scale: 1.08, particleIntensity: 0.4),
        StreakTier(threshold: 30, tint: PlayfulTokens.negative, scale: 1.16, particleIntensity: 0.7),
        StreakTier(threshold: 100, tint: PlayfulTokens.purple, scale: 1.24, particleIntensity: 1),
    ]
    var hapticsEnabled: Bool = true
}

/// Streak counter for any daily habit: glyph + day count with tier escalation
/// (tint, scale, spark particles). A zero streak renders gray and still; the
/// count pops when it rises. Pair with `StreakCalendar` in a detail sheet, and
/// present `StreakRepairSheet` from it when the streak breaks.
@available(iOS 17.0, *)
struct StreakIndicator: View {
    var count: Int
    var config: StreakIndicatorConfig = StreakIndicatorConfig()

    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tier: StreakTier? {
        config.tiers.filter { count >= $0.threshold }.max { $0.threshold < $1.threshold }
    }

    var body: some View {
        HStack(spacing: 6) {
            config.glyph
                .font(.system(size: config.glyphSize, weight: .bold))
                .foregroundStyle(tier?.tint ?? config.inactiveTint)
                .scaleEffect((tier?.scale ?? 1) * (popped ? 1.25 : 1))
                .background {
                    if let tier, tier.particleIntensity > 0, !reduceMotion {
                        StreakSparks(tint: tier.tint, intensity: tier.particleIntensity)
                    }
                }
            Text("\(count)")
                .font(config.countFont)
                .foregroundStyle(count > 0 ? config.countColor : config.inactiveTint)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: popped)
        .onChange(of: count) { old, new in
            guard new > old, !reduceMotion else { return }
            popped = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(220))
                popped = false
            }
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.9), trigger: count) { old, new in
            config.hapticsEnabled && new > old
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak")
        .accessibilityValue("\(count) days")
    }
}

/// Deterministic spark shower rising around the glyph; density scales with
/// intensity. Purely decorative and disabled under Reduce Motion by callers.
@available(iOS 17.0, *)
fileprivate struct StreakSparks: View {
    var tint: Color
    var intensity: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let sparkCount = Int(3 + intensity * 7)
                for index in 0..<sparkCount {
                    let seed = Double(index) * 1.61803
                    let period = 1.1 + seed.truncatingRemainder(dividingBy: 0.7)
                    let phase = ((time + seed) / period).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.2 + 0.6 * (seed.truncatingRemainder(dividingBy: 1)))
                    let y = size.height * (1 - phase) - 4
                    let radius = 1.4 + 1.2 * (1 - phase)
                    let rect = CGRect(x: x - radius, y: y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.opacity = (1 - phase) * 0.9
                    context.fill(Circle().path(in: rect), with: .color(tint))
                }
            }
        }
        .frame(width: 44, height: 48)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Streak tiers") {
    VStack(spacing: 28) {
        StreakIndicator(count: 0)
        StreakIndicator(count: 3)
        StreakIndicator(count: 12)
        StreakIndicator(count: 45)
        StreakIndicator(count: 150)
    }
    .padding(32)
}
