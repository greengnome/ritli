import Foundation
import Testing
@testable import Ritli

struct PomodoroSettingsTests {
    @Test("Defaults match the agreed Pomodoro behavior")
    func defaults() {
        let settings = PomodoroSettings()

        #expect(settings.focusDuration == 25 * 60)
        #expect(settings.shortBreakDuration == 5 * 60)
        #expect(settings.longBreakDuration == 15 * 60)
        #expect(settings.longBreakEvery == 4)
        #expect(!settings.autoStartBreaks)
        #expect(!settings.autoStartFocus)
        #expect(settings.soundEnabled)
        #expect(settings.hapticsEnabled)
        #expect(settings.notificationsEnabled)
        #expect(!settings.showTaskTitlesOnLockScreen)
    }

    @Test("Duration lookup uses the selected session kind", arguments: [
        (SessionKind.focus, TimeInterval(1_500)),
        (SessionKind.shortBreak, TimeInterval(300)),
        (SessionKind.longBreak, TimeInterval(900)),
    ])
    func durationLookup(kind: SessionKind, expected: TimeInterval) {
        #expect(PomodoroSettings().duration(for: kind) == expected)
    }
}
