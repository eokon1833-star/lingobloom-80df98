import SwiftUI

@available(iOS 17.0, *)
struct JourneyView: View {
    @Environment(LearningStore.self) private var store
    @State private var showingLesson = false

    private var sections: [ProgressPathSection] {
        let pathNodes = store.lessons.map { lesson in
            ProgressPathNodeModel(
                id: lesson.id,
                state: pathState(for: lesson.state),
                glyph: Image(systemName: lesson.glyph),
                title: lesson.title
            )
        }
        return [
            ProgressPathSection(
                id: "foundation",
                title: "Section 1 · Start speaking",
                subtitle: "Greetings, people, and everyday words",
                nodes: pathNodes
            )
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dailyProgress
                    .padding(.horizontal, PlayfulTokens.Spacing.screenMargin)
                    .padding(.top, PlayfulTokens.Spacing.sm)

                if store.activeLesson != nil {
                    ProgressPath(
                        sections: sections,
                        config: pathConfig,
                        onNodeTap: { node in
                            if node.state == .active {
                                showingLesson = true
                            }
                        }
                    )
                } else {
                    masteredState
                }
            }
            .background(PlayfulTokens.ground)
            .navigationTitle("")
            .toolbar { journeyToolbar }
            .fullScreenCover(isPresented: $showingLesson) {
                LessonFlowView()
            }
        }
    }

    private var dailyProgress: some View {
        VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xxs) {
                    Text("Today")
                        .font(PlayfulTokens.titleFont)
                        .foregroundStyle(PlayfulTokens.ink)
                    Text("\(store.minutesToday) of \(store.dailyGoalMinutes) minutes complete")
                        .font(PlayfulTokens.captionFont)
                        .foregroundStyle(PlayfulTokens.inkSecondary)
                }
                Spacer()
                Text(store.selectedLanguage.symbol)
                    .font(PlayfulTokens.display(28))
                    .accessibilityLabel(store.selectedLanguage.name)
            }

            ProgressView(value: store.dailyProgress)
                .tint(PlayfulTokens.accent)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .padding(.vertical, PlayfulTokens.Spacing.xs)
        }
    }

    private var masteredState: some View {
        VStack(spacing: PlayfulTokens.Spacing.lg) {
            Image(systemName: "star.circle.fill")
                .font(PlayfulTokens.display(64))
                .foregroundStyle(PlayfulTokens.accent)
            Text("Path complete!")
                .font(PlayfulTokens.displayFont)
                .foregroundStyle(PlayfulTokens.ink)
            Text("Your first \(store.selectedLanguage.name) path is mastered. Pick another language to start a fresh journey.")
                .font(PlayfulTokens.bodyFont)
                .foregroundStyle(PlayfulTokens.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PlayfulTokens.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var journeyToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: PlayfulTokens.Spacing.xs) {
                Image(systemName: "flame.fill")
                Text("\(store.streakDays)")
            }
            .font(PlayfulTokens.headlineFont)
            .foregroundStyle(PlayfulTokens.ink)
        }
        .sharedBackgroundVisibility(.hidden)

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

    private var pathConfig: ProgressPathConfig {
        ProgressPathConfig(
            activeFill: PlayfulTokens.accent,
            completedFill: PlayfulTokens.accent,
            legendaryFill: PlayfulTokens.accent,
            lockedFill: PlayfulTokens.track,
            nodeGlyphColor: PlayfulTokens.inkOnAccent,
            calloutText: "START",
            calloutFill: PlayfulTokens.accent,
            calloutTextColor: PlayfulTokens.inkOnAccent,
            bannerFill: PlayfulTokens.ink,
            bannerTextColor: PlayfulTokens.inkOnAccent,
            bannerFont: PlayfulTokens.headlineFont,
            bannerSubtitleFont: PlayfulTokens.captionFont,
            nodeSize: 72,
            nodeRimHeight: 6,
            verticalSpacing: PlayfulTokens.Spacing.xl,
            windingAmplitude: 72,
            windingPeriod: 8
        )
    }

    private func pathState(for state: LearningLesson.State) -> ProgressPathNodeState {
        switch state {
        case .completed:
            return .completed
        case .active:
            return .active
        case .locked:
            return .locked
        }
    }
}
