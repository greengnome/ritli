import SwiftUI

/// Colours for Home. At rest Home is paper with tomato accents; while a
/// session runs (or is paused) the screen takes the session's colour and the
/// text on it turns light. In dark mode that colour is a deep tint, with the
/// ring and main button in the accent (see `RitliTheme.sessionFill`).
struct HomeStyle: Equatable {
    let background: Color
    let foreground: Color
    let secondary: Color
    let ring: Color
    let track: Color
    let primaryFill: Color
    let primaryForeground: Color
    let controlFill: Color

    static let resting = HomeStyle(
        background: RitliTheme.paper,
        foreground: RitliTheme.ink,
        secondary: RitliTheme.stone,
        ring: RitliTheme.tomato,
        track: RitliTheme.tomatoTrack,
        primaryFill: RitliTheme.tomatoFill,
        primaryForeground: .white,
        controlFill: RitliTheme.sand
    )

    static func active(_ kind: SessionKind) -> HomeStyle {
        let fill = RitliTheme.sessionFill(for: kind)
        let accent = RitliTheme.sessionAccent(for: kind)
        return HomeStyle(
            background: fill,
            foreground: RitliTheme.onAccent,
            secondary: RitliTheme.onAccent.opacity(0.88),
            ring: accent,
            track: RitliTheme.onAccent.opacity(0.24),
            primaryFill: accent,
            primaryForeground: fill,
            controlFill: RitliTheme.onAccent.opacity(0.18)
        )
    }
}
