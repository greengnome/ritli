import SwiftUI

/// Colours for Home. At rest Home is paper with tomato accents; while a
/// session runs (or is paused) the whole screen takes the session's colour
/// and everything on it turns light.
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
        return HomeStyle(
            background: fill,
            foreground: RitliTheme.onAccent,
            secondary: RitliTheme.onAccent.opacity(0.88),
            ring: RitliTheme.onAccent,
            track: RitliTheme.onAccent.opacity(0.24),
            primaryFill: RitliTheme.onAccent,
            primaryForeground: fill,
            controlFill: RitliTheme.onAccent.opacity(0.18)
        )
    }
}
