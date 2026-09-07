import SwiftUI
import Testing
@testable import Ritli

struct AppAppearanceTests {
    @Test("Appearance choices map to the expected color-scheme override", arguments: [
        (AppAppearance.system, Optional<ColorScheme>.none),
        (AppAppearance.light, Optional(ColorScheme.light)),
        (AppAppearance.dark, Optional(ColorScheme.dark)),
    ])
    func preferredColorScheme(
        appearance: AppAppearance,
        expected: ColorScheme?
    ) {
        #expect(appearance.preferredColorScheme == expected)
    }

    @Test("Settings default to System and recover unknown stored values")
    func safeStoredValue() {
        let settings = PomodoroSettings()

        #expect(settings.appearance == .system)

        settings.appearance = .dark
        #expect(settings.appearanceRawValue == "dark")
        #expect(settings.appearance == .dark)

        settings.appearanceRawValue = "future-mode"
        #expect(settings.appearance == .system)
    }
}
