import SwiftUI

@main
struct LingoBloomApp: App {
    @State private var store = LearningStore()

    var body: some Scene {
        WindowGroup {
            LingoBloomRootView()
                .environment(store)
                .preferredColorScheme(.light)
        }
    }
}
