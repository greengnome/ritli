import SwiftUI
import UIKit

enum RitliTheme {
    static let accent = Color(red: 1, green: 0.36, blue: 0.29)
    static let accentSoft = Color(red: 1, green: 0.75, blue: 0.70)
    static let background = adaptiveColor(
        light: UIColor(red: 0.985, green: 0.975, blue: 0.96, alpha: 1),
        dark: .systemGroupedBackground
    )
    static let surface = adaptiveColor(
        light: UIColor.white.withAlphaComponent(0.92),
        dark: .secondarySystemGroupedBackground
    )
    static let success = Color(red: 0.31, green: 0.75, blue: 0.45)

    static let cardRadius: CGFloat = 24
    static let screenPadding: CGFloat = 20

    static func categoryColor(for token: String?) -> Color {
        switch token?.lowercased() {
        case "coral", "orange":
            accent
        case "green":
            .green
        case "blue":
            .blue
        case "purple":
            .purple
        default:
            .secondary
        }
    }

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
