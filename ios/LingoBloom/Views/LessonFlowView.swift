import SwiftUI

@available(iOS 17.0, *)
struct LessonFlowView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var promptIndex = 0
    @State private var selectedOption: String?
    @State private var hasCheckedAnswer = false
    @State private var correctAnswers = 0
    @State private var showingCompletion = false
    @State private var committedCompletion = false

    private var prompt: LessonPrompt {
        store.prompts[promptIndex]
    }

    private var lessonProgress: Double {
        Double(promptIndex) / Double(store.prompts.count)
    }

    private var continueState: TaskStepContinueState {
        if hasCheckedAnswer {
            return .advance
        }
        return selectedOption == nil ? .disabled : .check
    }

    private var optionItems: [OptionCardItem] {
        prompt.options.map { option in
            OptionCardItem(
                id: option,
                title: option,
                glyph: Image(systemName: optionGlyph(for: option)),
                tint: PlayfulTokens.accent
            )
        }
    }

    private var isCorrect: Bool {
        selectedOption == prompt.correctOption
    }

    var body: some View {
        Group {
            if showingCompletion {
                completionCeremony
            } else {
                lessonStep
            }
        }
        .background(PlayfulTokens.ground)
        .interactiveDismissDisabled()
    }

    private var lessonStep: some View {
        TaskStepScaffold(
            progress: lessonProgress,
            prompt: prompt.question,
            continueState: continueState,
            isCombo: correctAnswers > 1,
            config: lessonConfig,
            onClose: { dismiss() },
            onContinue: handleContinue
        ) {
            VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.lg) {
                Label(prompt.helper, systemImage: prompt.glyph)
                    .font(PlayfulTokens.bodyFont)
                    .foregroundStyle(PlayfulTokens.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                OptionCards(
                    items: optionItems,
                    selection: $selectedOption,
                    config: OptionCardsConfig(
                        cardFill: PlayfulTokens.surface,
                        cardBorder: PlayfulTokens.border,
                        selectedTint: PlayfulTokens.accent,
                        titleColor: PlayfulTokens.ink,
                        titleFont: PlayfulTokens.bodyFont,
                        cornerRadius: PlayfulTokens.radiusCard,
                        rimHeight: 3,
                        columns: 1,
                        hapticsEnabled: true
                    )
                )
                .disabled(hasCheckedAnswer)

                if hasCheckedAnswer {
                    feedbackBanner
                }
            }
        }
    }

    private var feedbackBanner: some View {
        HStack(alignment: .top, spacing: PlayfulTokens.Spacing.sm) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "arrow.uturn.forward.circle.fill")
                .font(PlayfulTokens.titleFont)
            VStack(alignment: .leading, spacing: PlayfulTokens.Spacing.xxs) {
                Text(isCorrect ? "Nice work!" : "Almost there")
                    .font(PlayfulTokens.headlineFont)
                Text(isCorrect ? "\(prompt.correctOption) is right." : "The answer is \(prompt.correctOption). Keep it in your review deck.")
                    .font(PlayfulTokens.bodyFont)
            }
        }
        .foregroundStyle(isCorrect ? PlayfulTokens.inkOnAccent : PlayfulTokens.ink)
        .padding(PlayfulTokens.Spacing.md)
        .background(isCorrect ? PlayfulTokens.accent : PlayfulTokens.surfaceRaised, in: RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous))
        .overlay {
            if !isCorrect {
                RoundedRectangle(cornerRadius: PlayfulTokens.radiusCard, style: .continuous)
                    .stroke(PlayfulTokens.border, lineWidth: 1)
            }
        }
    }

    private var completionCeremony: some View {
        CompletionCelebration(
            mode: .results(
                stats: [
                    CompletionCelebrationStat(id: "xp", label: "XP earned", value: 24, suffix: " XP", tint: PlayfulTokens.accent, glyph: Image(systemName: "bolt.fill")),
                    CompletionCelebrationStat(id: "score", label: "accuracy", value: accuracy, suffix: "%", tint: PlayfulTokens.ink, glyph: Image(systemName: "target"))
                ],
                bonusText: "Your next lesson is unlocked!"
            ),
            title: "Lesson complete!",
            subtitle: "You kept your streak moving.",
            config: celebrationConfig,
            onContinue: { dismiss() }
        )
        .background(PlayfulTokens.ground)
    }

    private var accuracy: Int {
        guard !store.prompts.isEmpty else { return 0 }
        return Int((Double(correctAnswers) / Double(store.prompts.count) * 100).rounded())
    }

    private var lessonConfig: TaskStepScaffoldConfig {
        TaskStepScaffoldConfig(
            accent: PlayfulTokens.accent,
            promptFont: PlayfulTokens.titleFont,
            promptColor: PlayfulTokens.ink,
            closeGlyph: Image(systemName: "xmark"),
            closeColor: PlayfulTokens.inkSecondary,
            checkTitle: "Check",
            continueTitle: "Continue",
            buttonConfig: DimensionalButtonConfig(
                face: PlayfulTokens.accent,
                foreground: PlayfulTokens.inkOnAccent,
                font: PlayfulTokens.buttonFont,
                cornerRadius: PlayfulTokens.radiusCard,
                rimHeight: PlayfulTokens.rimHeight,
                horizontalPadding: PlayfulTokens.Spacing.md,
                verticalPadding: PlayfulTokens.Spacing.md,
                fillsWidth: true,
                hapticsEnabled: true
            )
        )
    }

    private var celebrationConfig: CompletionCelebrationConfig {
        CompletionCelebrationConfig(
            headlineFont: PlayfulTokens.displayFont,
            headlineColor: PlayfulTokens.ink,
            subtitleFont: PlayfulTokens.bodyFont,
            subtitleColor: PlayfulTokens.inkSecondary,
            continueTitle: "Continue",
            buttonConfig: DimensionalButtonConfig(
                face: PlayfulTokens.accent,
                foreground: PlayfulTokens.inkOnAccent,
                font: PlayfulTokens.buttonFont,
                cornerRadius: PlayfulTokens.radiusCard,
                rimHeight: PlayfulTokens.rimHeight,
                horizontalPadding: PlayfulTokens.Spacing.md,
                verticalPadding: PlayfulTokens.Spacing.md,
                fillsWidth: true,
                hapticsEnabled: true
            ),
            cardFill: PlayfulTokens.surfaceRaised,
            bonusFill: PlayfulTokens.accentSoft,
            bonusTint: PlayfulTokens.accent,
            hapticsEnabled: true
        )
    }

    private func handleContinue() {
        guard selectedOption != nil else { return }

        if !hasCheckedAnswer {
            hasCheckedAnswer = true
            if isCorrect {
                correctAnswers += 1
            }
            return
        }

        if promptIndex + 1 < store.prompts.count {
            promptIndex += 1
            selectedOption = nil
            hasCheckedAnswer = false
            return
        }

        finishLesson()
    }

    private func finishLesson() {
        guard !committedCompletion else { return }
        committedCompletion = true
        store.completeCurrentLesson()
        showingCompletion = true
    }

    private func optionGlyph(for option: String) -> String {
        switch option {
        case "Hola", "Thank you", "Buenos días":
            return "hand.wave.fill"
        case "Gracias", "Please":
            return "heart.fill"
        case "Adiós", "Good night", "Hasta luego":
            return "moon.stars.fill"
        case "Por favor", "Friend", "amigo":
            return "person.2.fill"
        default:
            return "character.book.closed.fill"
        }
    }
}
