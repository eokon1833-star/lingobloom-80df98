import SwiftUI

@available(iOS 17.0, *)
struct LanguageLibraryView: View {
    @Environment(LearningStore.self) private var store
    @State private var query = ""

    private var filteredLanguages: [LanguageChoice] {
        guard !query.isEmpty else { return store.languages }
        return store.languages.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.nativeName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    featuredLanguage
                }

                Section("Explore 100+ languages") {
                    ForEach(filteredLanguages) { language in
                        Button {
                            store.chooseLanguage(language)
                        } label: {
                            HStack(spacing: PlayfulTokens.Spacing.md) {
                                Text(language.symbol)
                                    .font(PlayfulTokens.display(28))
                                    .frame(width: 44, height: 44)
                                    .background(PlayfulTokens.surfaceRaised, in: Circle())
                                VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xxs) {
                                    Text(language.name)
                                        .font(PlayfulTokens.headlineFont)
                                        .foregroundStyle(PlayfulTokens.ink)
                                    Text(language.nativeName)
                                        .font(PlayfulTokens.captionFont)
                                        .foregroundStyle(PlayfulTokens.inkSecondary)
                                }
                                Spacer()
                                if language.id == store.selectedLanguageID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(PlayfulTokens.titleFont)
                                        .foregroundStyle(PlayfulTokens.accent)
                                }
                            }
                            .padding(.vertical, PlayfulTokens.Spacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(PlayfulTokens.ground)
            .navigationTitle("Languages")
            .searchable(text: $query, prompt: "Search languages")
        }
    }

    private var featuredLanguage: some View {
        HStack(spacing: PlayfulTokens.Spacing.md) {
            Text(store.selectedLanguage.symbol)
                .font(PlayfulTokens.display(42))
                .frame(width: 70, height: 70)
                .background(PlayfulTokens.accentSoft, in: RoundedRectangle(cornerRadius: PlayfulTokens.radiusControl, style: .continuous))
            VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xxs) {
                Text("Learning now")
                    .font(PlayfulTokens.captionFont)
                    .foregroundStyle(PlayfulTokens.inkSecondary)
                Text(store.selectedLanguage.name)
                    .font(PlayfulTokens.titleFont)
                    .foregroundStyle(PlayfulTokens.ink)
                Text("Your next lesson is ready")
                    .font(PlayfulTokens.captionFont)
                    .foregroundStyle(PlayfulTokens.inkSecondary)
            }
            Spacer()
        }
        .padding(.vertical, PlayfulTokens.Spacing.sm)
    }
}
