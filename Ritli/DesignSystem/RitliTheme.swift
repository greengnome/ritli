import SwiftUI
import UIKit

/// Ritli's palette: flat, warm surfaces with one accent.
///
/// - Paper, sand and surface give depth without shadows or gradients.
/// - Tomato is the only colour on a resting screen. Leaf marks breaks and
///   finished work.
/// - While a session runs, Home fills with the session's colour, so the
///   state is readable from across the desk.
enum RitliTheme {
    // MARK: Ground

    /// The screen background.
    static let paper = adaptiveColor(light: 0xFAF7F2, dark: 0x171412)
    /// Controls that sit on paper: segmented tracks, icon buttons.
    static let sand = adaptiveColor(light: 0xF0E9DF, dark: 0x2A2522)
    /// Grouped rows and tiles that need to lift off paper.
    static let surface = adaptiveColor(light: 0xFFFFFF, dark: 0x221E1B)
    /// Dividers and empty tracks.
    static let hairline = adaptiveColor(light: 0xE6DDD0, dark: 0x3A332E)

    // MARK: Text

    static let ink = adaptiveColor(light: 0x1F1A17, dark: 0xF5EFE8)
    /// Captions and secondary values; passes 4.5:1 on paper and surface.
    static let stone = adaptiveColor(light: 0x6B635C, dark: 0xA69C92)
    /// Text and glyphs on tomato or leaf fills.
    static let onAccent = Color(hex: 0xFFF6EC)

    // MARK: Accent

    /// Large shapes only: the dial, chart bars, the category dot.
    static let tomato = Color(hex: 0xFF5C4A)
    /// Filled buttons, the focus screen and tinted text. White text on it
    /// passes 4.5:1, which plain tomato does not.
    static let tomatoInk = adaptiveColor(light: 0xCF3A24, dark: 0xFF6B5A)
    /// Fill behind white content (the focus screen, primary buttons). Stays
    /// dark enough for white text in both appearances.
    static let tomatoFill = Color(hex: 0xCF3A24)
    /// Breaks and finished work, as a fill behind white content.
    static let leafFill = Color(hex: 0x2C6B4A)
    /// Leaf for text and glyphs on paper.
    static let leaf = adaptiveColor(light: 0x2C6B4A, dark: 0x6CC790)
    /// The soft track behind tomato progress on paper.
    static let tomatoTrack = adaptiveColor(light: 0xF6D3CC, dark: 0x4A2A25)

    // MARK: Compatibility names used across features

    static let accent = tomatoInk
    static let accentSoft = tomatoTrack
    static let background = paper
    static let success = leaf

    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 28
    static let screenPadding: CGFloat = 24
    static let controlHeight: CGFloat = 56

    static func categoryColor(for token: String?) -> Color {
        switch token?.lowercased() {
        case "coral", "orange":
            tomato
        case "green":
            leaf
        case "blue":
            adaptiveColor(light: 0x3D6FA8, dark: 0x7FA8D9)
        case "purple":
            adaptiveColor(light: 0x7A5AA6, dark: 0xB49BD6)
        default:
            stone
        }
    }

    /// The full-screen colour while a session of `kind` runs.
    static func sessionFill(for kind: SessionKind) -> Color {
        switch kind {
        case .focus:
            tomatoFill
        case .shortBreak, .longBreak:
            leafFill
        }
    }

    private static func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(
            uiColor: UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

/// A filled capsule button at the standard control height.
struct RitliFilledButtonStyle: ButtonStyle {
    var fill: Color = RitliTheme.tomatoFill
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(minHeight: RitliTheme.controlHeight)
            .padding(.horizontal, 24)
            .background(fill, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Capsule())
    }
}

/// A round icon button drawn on sand (or any fill), at least 44pt.
struct RitliIconButtonStyle: ButtonStyle {
    var fill: Color = RitliTheme.sand
    var foreground: Color = RitliTheme.ink
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Circle())
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    /// Pure arithmetic, so it can run inside UIKit's dynamic-colour provider.
    nonisolated convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
