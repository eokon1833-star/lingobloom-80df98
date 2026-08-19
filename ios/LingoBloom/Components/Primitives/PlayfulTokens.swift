// 10x primitive: duolingo/design-tokens v1
import SwiftUI

/// The single theme for LingoBloom. Update these values to retheme the app.
@available(iOS 17.0, *)
enum PlayfulTokens {
    // MARK: Ground and ink
    static let ground: Color = Color(red: 1.00, green: 1.00, blue: 1.00)
    static let surface: Color = Color(red: 1.00, green: 1.00, blue: 1.00)
    static let surfaceRaised: Color = Color(red: 0.945, green: 0.961, blue: 0.976)
    static let ink: Color = Color(red: 0.059, green: 0.090, blue: 0.165)
    static let inkSecondary: Color = Color(red: 0.275, green: 0.345, blue: 0.435)
    static let inkOnAccent: Color = Color(red: 1.00, green: 1.00, blue: 1.00)
    static let inkDisabled: Color = Color(red: 0.620, green: 0.675, blue: 0.730)

    // MARK: Accent and semantic tones
    static let accent: Color = Color(red: 0.110, green: 0.690, blue: 0.965)
    static let accentSoft: Color = Color(red: 0.875, green: 0.965, blue: 0.995)
    static let accentSecondary: Color = Color(red: 0.059, green: 0.090, blue: 0.165)
    static let accentSecondarySoft: Color = Color(red: 0.910, green: 0.945, blue: 0.970)
    static let accentSecondaryDeep: Color = Color(red: 0.035, green: 0.055, blue: 0.105)
    static let positive: Color = Color(red: 0.040, green: 0.480, blue: 0.740)
    static let negative: Color = Color(red: 0.250, green: 0.430, blue: 0.570)
    static let negativeDeep: Color = Color(red: 0.059, green: 0.090, blue: 0.165)
    static let negativeSoft: Color = Color(red: 0.900, green: 0.945, blue: 0.970)
    static let warning: Color = Color(red: 0.110, green: 0.690, blue: 0.965)
    static let gold: Color = Color(red: 0.420, green: 0.805, blue: 1.000)
    static let purple: Color = Color(red: 0.265, green: 0.580, blue: 0.825)
    static let premiumGradient: [Color] = [accent, purple]
    static let premiumPurple: Color = purple
    static let border: Color = Color(red: 0.800, green: 0.855, blue: 0.900)
    static let track: Color = Color(red: 0.885, green: 0.920, blue: 0.950)

    // MARK: Layout
    static let radiusCard: CGFloat = 16
    static let radiusControl: CGFloat = 12
    static let radiusSheet: CGFloat = 24
    static let rimHeight: CGFloat = 4

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let huge: CGFloat = 48
        static let screenMargin: CGFloat = 16
    }

    // MARK: Type
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static let displayFont: Font = .system(.largeTitle, design: .rounded, weight: .heavy)
    static let titleFont: Font = .system(.title2, design: .rounded, weight: .heavy)
    static let headlineFont: Font = .system(.headline, design: .default, weight: .semibold)
    static let bodyFont: Font = .system(.body, design: .default, weight: .regular)
    static let captionFont: Font = .system(.caption, design: .default, weight: .regular)
    static let buttonFont: Font = .system(.body, design: .default, weight: .bold)
}
