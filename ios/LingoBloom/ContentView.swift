import SwiftUI

@available(iOS 17.0, *)
struct LingoBloomRootView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedTab = AppTab.journey

    var body: some View {
        TabView(selection: $selectedTab) {
            JourneyView()
                .tabItem { Label("Journey", systemImage: "figure.walk") }
                .tag(AppTab.journey)

            ReviewView()
                .tabItem { Label("Review", systemImage: "rectangle.stack.fill") }
                .tag(AppTab.review)

            LanguageLibraryView()
                .tabItem { Label("Languages", systemImage: "globe.americas.fill") }
                .tag(AppTab.languages)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppTab.profile)
        }
        .tint(PlayfulTokens.accent)
        .onChange(of: store.selectedLanguageID) { _, _ in
            selectedTab = .journey
        }
    }
}

@available(iOS 17.0, *)
private enum AppTab: Hashable {
    case journey
    case review
    case languages
    case profile
}
