// 10x primitive: duolingo/task-step-scaffold v1
import SwiftUI

@available(iOS 17.0, *)
struct TaskStepProgressBarConfig {
    var track: Color = PlayfulTokens.track
    var fill: Color = PlayfulTokens.accent
    var comboFill: Color = PlayfulTokens.warning
    var recoveryFlash: Color = PlayfulTokens.negative
    var shine: Color = .white.opacity(0.35)
    var height: CGFloat = 16
    /// Seconds between shine sweeps across the filled region.
    var shinePeriod: Double = 2.4
    var hapticsEnabled: Bool = true
}

/// Thick rounded step progress bar: springy segment fill, a periodic shine
/// sweeping the filled region, a combo-glow state, and a red-flash spring-back
/// when progress is lost (mistake recovery). Rendered by `TaskStepScaffold`'s
/// top bar and usable standalone.
@available(iOS 17.0, *)
struct TaskStepProgressBar: View {
    /// Fill fraction in 0...1. Increases spring forward; decreases flash red.
    var progress: Double
    /// Combo state: fill switches to `comboFill` and pulses an outer glow.
    var isCombo: Bool = false
    var config: TaskStepProgressBarConfig = TaskStepProgressBarConfig()

    @State private var flashingLoss = false
    @State private var lastProgress: Double = 0
    @State private var glowPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }
    private var fillColor: Color {
        if flashingLoss { return config.recoveryFlash }
        return isCombo ? config.comboFill : config.fill
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(config.height, proxy.size.width * clamped)
            ZStack(alignment: .leading) {
                Capsule().fill(config.track)
                Capsule()
                    .fill(fillColor)
                    .frame(width: width)
                    .overlay(alignment: .top) {
                        // Inner top highlight: constant part of the bar's look.
                        Capsule()
                            .fill(.white.opacity(0.25))
                            .frame(width: max(0, width - 16), height: config.height * 0.28)
                            .padding(.top, config.height * 0.18)
                            .padding(.horizontal, 8)
                    }
                    .overlay {
                        if !reduceMotion {
                            shineSweep(width: width)
                        }
                    }
                    .clipShape(Capsule())
                    .shadow(color: isCombo && glowPulse ? config.comboFill.opacity(0.7) : .clear,
                            radius: 8)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.72), value: clamped)
            .animation(.easeInOut(duration: 0.3), value: isCombo)
        }
        .frame(height: config.height)
        .onChange(of: progress) { old, new in
            lastProgress = old
            guard new < old else { return }
            flashingLoss = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeOut(duration: 0.25)) { flashingLoss = false }
            }
        }
        .onChange(of: isCombo) { _, combo in
            guard combo, !reduceMotion else { glowPulse = false; return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .sensoryFeedback(.increase, trigger: clamped) { old, new in
            config.hapticsEnabled && new > old
        }
        .sensoryFeedback(.error, trigger: flashingLoss) { _, new in
            config.hapticsEnabled && new
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }

    /// A soft light blob translating across the filled region on a timeline.
    private func shineSweep(width: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = (time.truncatingRemainder(dividingBy: config.shinePeriod)) / config.shinePeriod
            let blobWidth = config.height * 2.2
            let x = CGFloat(phase) * (width + blobWidth * 2) - blobWidth
            Capsule()
                .fill(config.shine)
                .frame(width: blobWidth, height: config.height)
                .blur(radius: 3)
                .offset(x: x)
                .frame(width: width, alignment: .leading)
        }
        .allowsHitTesting(false)
    }
}

#Preview("Task step progress bar") {
    struct Demo: View {
        @State private var progress = 0.35
        @State private var combo = false
        var body: some View {
            VStack(spacing: 32) {
                TaskStepProgressBar(progress: progress, isCombo: combo)
                TaskStepProgressBar(progress: 0.8, isCombo: true,
                                    config: TaskStepProgressBarConfig())
                HStack {
                    Button("Answer") { progress = min(1, progress + 0.15) }
                    Button("Mistake") { progress = max(0, progress - 0.15) }
                    Toggle("Combo", isOn: $combo).fixedSize()
                }
            }
            .padding(24)
        }
    }
    return Demo()
}
