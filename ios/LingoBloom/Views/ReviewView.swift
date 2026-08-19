import SwiftUI

@available(iOS 17.0, *)
struct ReviewView: View {
    @Environment(LearningStore.self) private var store
    @State private var knownCards: Set<String> = []

    private let cards: [(id: String, word: String, meaning: String, glyph: String)] = [
        ("hola", "hola", "hello", "hand.wave.fill"),
        ("gracias", "gracias", "thank you", "heart.fill"),
        ("amigo", "amigo", "friend", "person.2.fill"),
        ("agua", "agua", "water", "drop.fill"),
        ("casa", "casa", "home", "house.fill")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xxl) {
                    reviewHero
                    cardsSection
                }
                .padding(.horizontal, PlayfulTokens.Spacing.screenMargin)
                .padding(.vertical, PlayfulTokens.Spacing.lg)
            }
            .background(PlayfulTokens.ground)
            .navigationTitle("Review")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: PlayfulTokens.Spacing.xxs) {
                        Image(systemName: "bolt.fill")
                        Text("\(store.xp)")
                    }
                    .font(PlayfulTokens.headlineFont)
                    .foregroundStyle(PlayfulTokens.accent)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    private var reviewHero: some View {
        VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.sm) {
            Text("Words ready")
                .font(PlayfulTokens.captionFont)
                .foregroundStyle(PlayfulTokens.inkSecondary)
            Text("5")
                .font(PlayfulTokens.display(56))
                .foregroundStyle(PlayfulTokens.accent)
                .monospacedDigit()
            Text("Quick recall keeps your \(store.selectedLanguage.name) growing.")
                .font(PlayfulTokens.bodyFont)
                .foregroundStyle(PlayfulTokens.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PlayfulTokens.Spacing.lg)
        .background(PlayfulTokens.accentSoft, in: RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous))
    }

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.md) {
            Text("Practice")
                .font(PlayfulTokens.titleFont)
                .foregroundStyle(PlayfulTokens.ink)

            ForEach(cards, id: \.id) { card in
                Button {
                    if knownCards.contains(card.id) {
                        knownCards.remove(card.id)
                    } else {
                        knownCards.insert(card.id)
                    }
                } label: {
                    HStack(spacing: PlayfulTokens.Spacing.md) {
                        Image(systemName: card.glyph)
                            .font(PlayfulTokens.titleFont)
                            .foregroundStyle(PlayfulTokens.accent)
                            .frame(width: 44, height: 44)
                            .background(PlayfulTokens.accentSoft, in: Circle())

                        VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xxs) {
                            Text(card.word)
                                .font(PlayfulTokens.headlineFont)
                                .foregroundStyle(PlayfulTokens.ink)
                            Text(knownCards.contains(card.id) ? card.meaning : "Tap to reveal")
                                .font(PlayfulTokens.bodyFont)
                                .foregroundStyle(PlayfulTokens.inkSecondary)
                        }
                        Spacer()
                        Image(systemName: knownCards.contains(card.id) ? "checkmark.circle.fill" : "chevron.right")
                            .font(PlayfulTokens.headlineFont)
                            .foregroundStyle(knownCards.contains(card.id) ? PlayfulTokens.accent : PlayfulTokens.inkSecondary)
                    }
                    .padding(PlayfulTokens.Spacing.md)
                    .background(PlayfulTokens.surface, in: RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous)
                            .stroke(PlayfulTokens.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
