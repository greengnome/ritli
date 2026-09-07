import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerSettingsDraftTests {
    @Test("A draft reflects every editable timer preference")
    func reflectsSettings() {
        let settings = PomodoroSettings(
            focusDuration: 45 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 30 * 60,
            longBreakEvery: 3,
            autoStartBreaks: true,
            autoStartFocus: true,
            soundEnabled: false,
            hapticsEnabled: false,
            notificationsEnabled: false,
            showTaskTitlesOnLockScreen: true
        )

        let draft = TimerSettingsDraft(settings: settings)

        #expect(draft.focusMinutes == 45)
        #expect(draft.shortBreakMinutes == 10)
        #expect(draft.longBreakMinutes == 30)
        #expect(draft.longBreakEvery == 3)
        #expect(draft.autoStartBreaks)
        #expect(draft.autoStartFocus)
        #expect(!draft.soundEnabled)
        #expect(!draft.hapticsEnabled)
        #expect(!draft.notificationsEnabled)
        #expect(draft.showTaskTitlesOnLockScreen)
    }

    @Test("Applying a draft updates future sessions without changing the active one")
    func appliesToFutureSessions() throws {
        let harness = TimerEngineHarness()
        let activeSession = try harness.engine.startFocus()
        var draft = TimerSettingsDraft(settings: harness.settings)
        draft.focusMinutes = 45
        draft.shortBreakMinutes = 10
        draft.longBreakMinutes = 30
        draft.longBreakEvery = 3
        draft.autoStartBreaks = true
        draft.autoStartFocus = true
        draft.soundEnabled = false
        draft.hapticsEnabled = false
        draft.notificationsEnabled = false
        draft.showTaskTitlesOnLockScreen = true

        draft.apply(to: harness.settings)

        #expect(activeSession.plannedDuration == 25 * 60)
        #expect(harness.settings.focusDuration == 45 * 60)
        #expect(harness.settings.shortBreakDuration == 10 * 60)
        #expect(harness.settings.longBreakDuration == 30 * 60)
        #expect(harness.settings.longBreakEvery == 3)
        #expect(harness.settings.autoStartBreaks)
        #expect(harness.settings.autoStartFocus)
        #expect(!harness.settings.soundEnabled)
        #expect(!harness.settings.hapticsEnabled)
        #expect(!harness.settings.notificationsEnabled)
        #expect(harness.settings.showTaskTitlesOnLockScreen)

        try harness.engine.cancel()
        let nextSession = try harness.engine.startFocus()

        #expect(nextSession.plannedDuration == 45 * 60)
        #expect(harness.notifications.schedules.count == 1)
    }

    @Test("Applying invalid numeric values preserves model invariants")
    func normalizesInvalidValues() {
        let settings = PomodoroSettings()
        var draft = TimerSettingsDraft(settings: settings)
        draft.focusMinutes = 0
        draft.shortBreakMinutes = -5
        draft.longBreakMinutes = 0
        draft.longBreakEvery = 0

        draft.apply(to: settings)

        #expect(settings.focusDuration == 60)
        #expect(settings.shortBreakDuration == 60)
        #expect(settings.longBreakDuration == 60)
        #expect(settings.longBreakEvery == 1)
    }
}
