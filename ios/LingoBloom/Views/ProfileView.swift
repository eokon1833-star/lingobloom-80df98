import SwiftUI

@available(iOS 17.0, *)
struct ProfileView: View {
    @Environment(LearningStore.self) private var store
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PlayfulTokens.Spacing.xxl) {
                    profileHero
                    goalCard
                    statsCard
                    localDemoNote
                    resetButton
                }
                .padding(.horizontal, PlayfulTokens.Spacing.screenMargin)
                .padding(.vertical, PlayfulTokens.Spacing.lg)
            }
            .background(PlayfulTokens.ground)
            .navigationTitle("Profile")
            .confirmationDialog("Reset demo progress?", isPresented: $showingResetConfirmation) {
                Button("Reset Progress", role: .destructive) {
                    store.resetDemoProgress()
                }
            } message: {
                Text("This restores the seeded local lesson path and daily progress.")
            }
        }
    }

    private var profileHero: some View {
        VStack(spacing: PlayfulTokens.Spacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .font(PlayfulTokens.display(72))
                .foregroundStyle(PlayfulTokens.accent)
            Text("Language explorer")
                .font(PlayfulTokens.titleFont)
                .foregroundStyle(PlayfulTokens.ink)
            Text("Learning \(store.selectedLanguage.name)")
                .font(PlayfulTokens.bodyFont)
                .foregroundStyle(PlayfulTokens.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.md) {
            Text("Daily goal")
                .font(PlayfulTokens.titleFont)
                .foregroundStyle(PlayfulTokens.ink)
            Picker("Daily goal", selection: Binding(
                get: { store.dailyGoalMinutes },
                set: { store.updateDailyGoal(to: $0) }
            )) {
                Text("5 min").tag(5)
                Text("10 min").tag(10)
                Text("15 min").tag(15)
                Text("20 min").tag(20)
            }
            .pickerStyle(.segmented)
            Text("\(store.minutesToday) of \(store.dailyGoalMinutes) minutes practiced today")
                .font(PlayfulTokens.bodyFont)
                .foregroundStyle(PlayfulTokens.inkSecondary)
        }
        .padding(PlayfulTokens.Spacing.lg)
        .background(PlayfulTokens.surfaceRaised, in: RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous))
    }

    private var statsCard: some View {
        HStack(spacing: PlayfulTokens.Spacing.sm) {
            ProfileMetric(value: "\(store.streakDays)", label: "day streak", glyph: "flame.fill")
            ProfileMetric(value: "\(store.xp)", label: "total XP", glyph: "bolt.fill")
            ProfileMetric(value: "\(store.completedCount)", label: "lessons", glyph: "checkmark.circle.fill")
        }
    }

    private var localDemoNote: some View {
        Text("LingoBloom V1 uses seeded on-device lessons and local progress. No account or language service is connected.")
            .font(PlayfulTokens.captionFont)
            .foregroundStyle(PlayfulTokens.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            showingResetConfirmation = true
        } label: {
            Text("Reset demo progress")
                .font(PlayfulTokens.headlineFont)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.bordered)
        .tint(PlayfulTokens.ink)
    }
}

@available(iOS 17.0, *)
private struct ProfileMetric: View {
    let value: String
    let label: String
    let glyph: String

    var body: some View {
        VStack(spacing: PlayfulTokens.Spacing.xs) {
            Image(systemName: glyph)
                .font(PlayfulTokens.headlineFont)
                .foregroundStyle(PlayfulTokens.accent)
            Text(value)
                .font(PlayfulTokens.titleFont)
                .foregroundStyle(PlayfulTokens.ink)
                .monospacedDigit()
            Text(label)
                .font(PlayfulTokens.captionFont)
                .foregroundStyle(PlayfulTokens.inkSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(PlayfulTokens.Spacing.sm)
        .background(PlayfulTokens.surfaceRaised, in: RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous))
    }
}
