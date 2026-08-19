// 10x primitive: duolingo/streak-indicator v1
import SwiftUI

@available(iOS 17.0, *)
struct StreakRepairSheetConfig {
    var flameGlyph: Image = Image(systemName: "flame.fill")
    var brokenTint: Color = PlayfulTokens.inkDisabled
    var repairedTint: Color = PlayfulTokens.warning
    var title: String = "Repair your streak?"
    var messageFormat: String = "Your %d-day streak is one payment away from being saved."
    var titleFont: Font = PlayfulTokens.titleFont
    var messageFont: Font = .system(.subheadline, design: .rounded, weight: .medium)
    var currencyGlyph: Image = Image(systemName: "diamond.fill")
    var currencyTint: Color = PlayfulTokens.accentSecondary
    var confirmTitle: String = "Repair streak"
    var declineTitle: String = "No thanks"
    var confirmConfig: DimensionalButtonConfig = DimensionalButtonConfig(face: PlayfulTokens.warning)
    var hapticsEnabled: Bool = true
}

/// Optional modal offer the streak indicator can present when a streak breaks:
/// dimmed flame with the lost count, a price chip, and confirm/decline.
/// Confirming relights the flame with a pop before reporting the purchase.
/// Present inside `.sheet`.
@available(iOS 17.0, *)
struct StreakRepairSheet: View {
    var streakDays: Int
    var price: Int
    var config: StreakRepairSheetConfig = StreakRepairSheetConfig()
    var onConfirm: () -> Void = {}
    var onDecline: () -> Void = {}

    @State private var repaired = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                config.flameGlyph
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(repaired ? config.repairedTint : config.brokenTint)
                    .scaleEffect(repaired ? 1.15 : 1)
                    .rotationEffect(.degrees(repaired ? 0 : -8))
                Text("\(streakDays)")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .offset(y: 14)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: repaired)
            .accessibilityHidden(true)

            Text(config.title)
                .font(config.titleFont)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(String(format: config.messageFormat, streakDays))
                .font(config.messageFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            priceChip

            VStack(spacing: 10) {
                DimensionalButton(config.confirmTitle, config: config.confirmConfig) {
                    guard !repaired else { return }
                    repaired = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 650))
                        onConfirm()
                    }
                }
                Button(config.declineTitle, action: onDecline)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
        }
        .padding(24)
        .sensoryFeedback(.success, trigger: repaired) { _, new in
            config.hapticsEnabled && new
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(config.title) \(streakDays) days, price \(price)")
    }

    private var priceChip: some View {
        HStack(spacing: 6) {
            config.currencyGlyph
                .font(.system(size: 14, weight: .bold))
            Text("\(price)")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .monospacedDigit()
        }
        .foregroundStyle(config.currencyTint)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(config.currencyTint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(config.currencyTint.opacity(0.4), lineWidth: 1.5))
        .accessibilityLabel("Price \(price)")
    }
}

#Preview("Streak repair") {
    struct Demo: View {
        @State private var presented = true
        var body: some View {
            Button("Show offer") { presented = true }
                .sheet(isPresented: $presented) {
                    StreakRepairSheet(streakDays: 47, price: 350,
                                      onConfirm: { presented = false },
                                      onDecline: { presented = false })
                        .presentationDetents([.medium])
                }
        }
    }
    return Demo()
}
