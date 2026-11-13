import SwiftUI
import UIKit

/// Ritli's palette: flat, warm surfaces with one accent.
///
/// - Paper, sand and surface give depth without shadows or gradients.
/// - Tomato (a soft coral, with terracotta for buttons) is the only colour
///   on a resting screen. Leaf marks breaks and
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
    static let tomato = adaptiveColor(light: 0xE07A5F, dark: 0xE8846B)
    /// Tinted text and small glyphs: links, the selected tab, play icons.
    static let tomatoInk = adaptiveColor(light: 0xB5523E, dark: 0xEE9A85)
    /// Fill behind white content (primary buttons). Light text on it passes
    /// 4.5:1 in both appearances.
    static let tomatoFill = Color(hex: 0xB5523E)
    /// Breaks and finished work, as a fill behind white content.
    static let leafFill = Color(hex: 0x2C6B4A)
    /// Leaf for text and glyphs on paper.
    static let leaf = adaptiveColor(light: 0x2C6B4A, dark: 0x6CC790)
    /// The soft track behind tomato progress on paper.
    static let tomatoTrack = adaptiveColor(light: 0xF0CDC2, dark: 0x5A3329)

    // MARK: Session screens

    // While a session runs, Home takes its colour. In light mode the whole
    // screen fills with it; in dark mode a full-colour screen glares, so the
    // screen becomes a deep tint and the ring and main button carry the colour.

    /// The screen behind a focus session.
    static let focusScreen = adaptiveColor(light: 0xB5523E, dark: 0x3A1E17)
    /// The screen behind a break.
    static let breakScreen = adaptiveColor(light: 0x2C6B4A, dark: 0x14271D)
    /// The ring and main button during focus.
    static let focusAccent = adaptiveColor(light: 0xFFF6EC, dark: 0xE8846B)
    /// The ring and main button during a break.
    static let breakAccent = adaptiveColor(light: 0xFFF6EC, dark: 0x6CC790)

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

    /// The screen colour while a session of `kind` runs.
    static func sessionFill(for kind: SessionKind) -> Color {
        switch kind {
        case .focus:
            focusScreen
        case .shortBreak, .longBreak:
            breakScreen
        }
    }

    /// The ring and main-button colour while a session of `kind` runs.
    static func sessionAccent(for kind: SessionKind) -> Color {
        switch kind {
        case .focus:
            focusAccent
        case .shortBreak, .longBreak:
            breakAccent
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
