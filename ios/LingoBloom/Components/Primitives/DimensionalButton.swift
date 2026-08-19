// 10x primitive: duolingo/dimensional-button v1
import SwiftUI

/// A 3D press-collapse button: a raised face resting on a solid bottom rim.
/// Pressing translates the face down onto the rim with a stiff spring; releasing
/// pops it back. Defaults come from `PlayfulTokens`; every slot stays
/// overridable at the call site.
@available(iOS 17.0, *)
struct DimensionalButtonConfig {
    /// Face fill; the set's signature action green by default.
    var face: Color = PlayfulTokens.accent
    /// Rim color. `nil` derives a darker rim by compositing black over the face.
    var rim: Color? = nil
    var foreground: Color = PlayfulTokens.inkOnAccent
    /// Optional 2pt border drawn on the face (used by the secondary style).
    var border: Color? = nil
    var font: Font = PlayfulTokens.buttonFont
    var cornerRadius: CGFloat = PlayfulTokens.radiusCard
    /// Height of the visible bottom rim; also the press travel distance.
    var rimHeight: CGFloat = PlayfulTokens.rimHeight
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 14
    var fillsWidth: Bool = true
    var hapticsEnabled: Bool = true

    /// Outline variant: light face, hairline border, shallow gray rim.
    static var secondary: DimensionalButtonConfig {
        DimensionalButtonConfig(
            face: PlayfulTokens.surface,
            rim: PlayfulTokens.border,
            foreground: PlayfulTokens.ink,
            border: PlayfulTokens.border
        )
    }
}

@available(iOS 17.0, *)
struct DimensionalButtonStyle: ButtonStyle {
    var config: DimensionalButtonConfig = DimensionalButtonConfig()
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        let shape = RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
        let face = isEnabled ? config.face : Color(.systemGray5)
        let travel = config.rimHeight

        configuration.label
            .font(config.font)
            .foregroundStyle(isEnabled ? config.foreground : Color(.systemGray2))
            .padding(.horizontal, config.horizontalPadding)
            .padding(.vertical, config.verticalPadding)
            .frame(maxWidth: config.fillsWidth ? .infinity : nil)
            .background {
                shape.fill(face)
                    .overlay {
                        if let border = config.border, isEnabled {
                            shape.strokeBorder(border, lineWidth: 2)
                        }
                    }
            }
            .background {
                // Static rim the face collapses onto.
                ZStack {
                    if let rim = config.rim {
                        shape.fill(rim)
                    } else {
                        shape.fill(face)
                        shape.fill(Color.black.opacity(0.28))
                    }
                }
                .offset(y: isEnabled ? travel : 0)
            }
            .offset(y: pressed ? travel : 0)
            .padding(.bottom, isEnabled ? travel : 0)
            .animation(.spring(response: 0.12, dampingFraction: 0.9), value: pressed)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: pressed) { _, newValue in
                config.hapticsEnabled && newValue
            }
    }
}

/// Convenience wrapper adding loading and disabled handling around a `Button`
/// styled with `DimensionalButtonStyle`.
@available(iOS 17.0, *)
struct DimensionalButton<Label: View>: View {
    var config: DimensionalButtonConfig = DimensionalButtonConfig()
    var isLoading: Bool = false
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            ZStack {
                label().opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(config.foreground)
                        .accessibilityLabel("Loading")
                }
            }
        }
        .buttonStyle(DimensionalButtonStyle(config: config))
        .disabled(isLoading)
    }
}

@available(iOS 17.0, *)
extension DimensionalButton where Label == Text {
    init(_ title: String,
         config: DimensionalButtonConfig = DimensionalButtonConfig(),
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.init(config: config, isLoading: isLoading, action: action) { Text(title) }
    }
}

#Preview("Dimensional button states") {
    VStack(spacing: 20) {
        DimensionalButton("Continue") {}
        DimensionalButton("Secondary", config: .secondary) {}
        DimensionalButton("Disabled") {}.disabled(true)
        DimensionalButton("Loading", isLoading: true) {}
        DimensionalButton(config: DimensionalButtonConfig(face: PlayfulTokens.accentSecondary,
                                                          cornerRadius: 28,
                                                          horizontalPadding: 20, fillsWidth: false),
                          action: {}) {
            Image(systemName: "arrow.right")
        }
    }
    .padding(24)
    .background(PlayfulTokens.ground)
}
