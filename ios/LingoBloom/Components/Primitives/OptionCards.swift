// 10x primitive: duolingo/option-cards v1
import SwiftUI

@available(iOS 17.0, *)
struct OptionCardsConfig {
    var cardFill: Color = PlayfulTokens.surface
    var cardBorder: Color = PlayfulTokens.border
    var selectedTint: Color = PlayfulTokens.accentSecondary
    var titleColor: Color = PlayfulTokens.ink
    var titleFont: Font = .system(.subheadline, design: .rounded, weight: .semibold)
    var cornerRadius: CGFloat = PlayfulTokens.radiusCard
    var rimHeight: CGFloat = 2
    var columns: Int = 2
    var hapticsEnabled: Bool = true
}

@available(iOS 17.0, *)
struct OptionCardItem: Identifiable {
    let id: String
    var title: String
    /// Artwork slot; neutral placeholder glyph when nil.
    var glyph: Image? = nil
    /// Artwork tint; keeps the grid colorful like real image choices.
    /// `nil` falls back to a neutral gray.
    var tint: Color? = nil
}

/// Image-option answer grid (2 columns by default): each card is artwork over
/// a caption, with a press scale and a selection ring. Works for any
/// pick-one choice: quiz answers, onboarding goals, avatar picks.
@available(iOS 17.0, *)
struct OptionCards: View {
    var items: [OptionCardItem]
    @Binding var selection: String?
    var config: OptionCardsConfig = OptionCardsConfig()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12),
                            count: max(config.columns, 1))
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items) { item in
                card(item)
            }
        }
        .sensoryFeedback(.selection, trigger: selection) { _, new in
            config.hapticsEnabled && new != nil
        }
        .accessibilityElement(children: .contain)
    }

    private func card(_ item: OptionCardItem) -> some View {
        let isSelected = selection == item.id
        let shape = RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
        return Button {
            selection = isSelected ? nil : item.id
        } label: {
            VStack(spacing: 10) {
                (item.glyph ?? Image(systemName: "photo"))
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 88)
                    .foregroundStyle(item.tint ?? (isSelected ? config.selectedTint : Color(.systemGray2)))
                Text(item.title)
                    .font(config.titleFont)
                    .foregroundStyle(isSelected ? config.selectedTint : config.titleColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    shape.fill(config.cardFill)
                    if isSelected {
                        shape.fill(config.selectedTint.opacity(0.1))
                    }
                    shape.strokeBorder(isSelected ? config.selectedTint : config.cardBorder,
                                       lineWidth: isSelected ? 2.5 : 2)
                }
                .background(shape.fill(config.cardBorder).offset(y: config.rimHeight))
            }
        }
        .buttonStyle(OptionPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Press scale used by option cards (0.96 with a soft spring).
@available(iOS 17.0, *)
fileprivate struct OptionPressStyle: ButtonStyle {
    var reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview("Option cards") {
    struct Demo: View {
        @State private var selection: String? = "b"
        var body: some View {
            OptionCards(items: [
                OptionCardItem(id: "a", title: "Apple", glyph: Image(systemName: "apple.logo")),
                OptionCardItem(id: "b", title: "Leaf", glyph: Image(systemName: "leaf.fill")),
                OptionCardItem(id: "c", title: "House", glyph: Image(systemName: "house.fill")),
                OptionCardItem(id: "d", title: "Cloud", glyph: Image(systemName: "cloud.fill")),
            ], selection: $selection)
            .padding(24)
        }
    }
    return Demo()
}
