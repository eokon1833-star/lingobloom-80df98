// 10x primitive: duolingo/task-step-scaffold v1
import SwiftUI

@available(iOS 17.0, *)
enum TaskStepContinueState: Equatable {
    /// No answer yet: bottom button is grayed out and inert.
    case disabled
    /// Answer selected: bottom button offers to check it.
    case check
    /// Answer graded: bottom button advances to the next step.
    case advance
}

@available(iOS 17.0, *)
struct TaskStepScaffoldConfig {
    var accent: Color = PlayfulTokens.accent
    var promptFont: Font = .system(.title2, design: .rounded, weight: .bold)
    var promptColor: Color = PlayfulTokens.ink
    var closeGlyph: Image = Image(systemName: "xmark")
    var closeColor: Color = Color(.systemGray)
    var checkTitle: String = "Check"
    var continueTitle: String = "Continue"
    var buttonConfig: DimensionalButtonConfig = DimensionalButtonConfig()
    /// Styling for the built-in top progress bar (absorbed lesson-progress-bar).
    var progressBarConfig: TaskStepProgressBarConfig = TaskStepProgressBarConfig()
}

/// Step-screen frame for any staged task flow: top close + springy progress
/// bar, prompt area, a caller-supplied answer area, and an anchored bottom bar
/// whose button moves through disabled → check → continue. The top bar is the
/// full `TaskStepProgressBar` (shine sweep, combo glow, red mistake-recovery
/// flash), absorbed from the old lesson-progress-bar primitive.
@available(iOS 17.0, *)
struct TaskStepScaffold<AnswerArea: View>: View {
    /// Flow progress in 0...1, animated on change (decreases flash red).
    var progress: Double
    var prompt: String
    var continueState: TaskStepContinueState = .disabled
    /// Combo/hot-streak state: the top bar glows in the combo tint.
    var isCombo: Bool = false
    var config: TaskStepScaffoldConfig = TaskStepScaffoldConfig()
    var onClose: () -> Void = {}
    var onContinue: () -> Void = {}
    @ViewBuilder var answerArea: () -> AnswerArea

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Text(prompt)
                .font(config.promptFont)
                .foregroundStyle(config.promptColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)

            answerArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                config.closeGlyph
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(config.closeColor)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")

            TaskStepProgressBar(progress: progress, isCombo: isCombo,
                                config: progressBarConfig)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            DimensionalButton(buttonTitle, config: buttonConfig, action: onContinue)
                .disabled(continueState == .disabled)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .background(.bar)
    }

    private var buttonTitle: String {
        switch continueState {
        case .disabled, .check: config.checkTitle
        case .advance: config.continueTitle
        }
    }

    private var buttonConfig: DimensionalButtonConfig {
        var button = config.buttonConfig
        if continueState != .disabled { button.face = config.accent }
        return button
    }

    private var progressBarConfig: TaskStepProgressBarConfig {
        var bar = config.progressBarConfig
        bar.fill = config.accent
        return bar
    }
}

#Preview("Task step scaffold") {
    struct Demo: View {
        @State private var state: TaskStepContinueState = .disabled
        @State private var progress = 0.3
        var body: some View {
            TaskStepScaffold(progress: progress, prompt: "Translate this sentence",
                             continueState: state,
                             onContinue: {
                                 state = state == .check ? .advance : .check
                                 if state == .check { progress += 0.1 }
                             }) {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)).frame(height: 120)
                    Button("Select an answer") { state = .check }
                }
            }
        }
    }
    return Demo()
}
