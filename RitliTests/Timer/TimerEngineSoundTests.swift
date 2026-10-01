import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerEngineSoundTests {
    @Test("Focus and both breaks sound independently of notification and haptic preferences", arguments: [
        SessionKind.focus, .shortBreak, .longBreak,
    ])
    func soundsWithNotificationsAndHapticsOff(kind: SessionKind) throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(
            focusDuration: 1, shortBreakDuration: 1, longBreakDuration: 1,
            timerSound: .clearChime, hapticsEnabled: false, notificationsEnabled: false
        ))
        let session: FocusSession
        switch kind {
        case .focus: session = try harness.engine.startFocus()
        case .shortBreak: session = try harness.engine.startShortBreak()
        case .longBreak: session = try harness.engine.startLongBreak()
        }
        harness.clock.advance(by: 1)
        try harness.engine.refresh()
        try harness.engine.refresh()

        #expect(harness.completionSound.playbacks == [
            .init(id: session.id, sound: .clearChime, hasScheduledNotification: false),
        ])
        #expect(harness.notifications.schedules.isEmpty)
        #expect(harness.feedback.events.isEmpty)
    }

    @Test("Restoring or catching up an expired timer does not replay its sound")
    func doesNotReplayPastCompletion() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 1, timerSound: .gentleBell))
        try harness.engine.startFocus()
        harness.clock.advance(by: 10)
        try harness.engine.refresh(playCompletionSound: false)
        #expect(harness.completionSound.playbacks.isEmpty)

        let restored = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 1, timerSound: .gentleBell))
        try restored.engine.startFocus()
        restored.clock.advance(by: 1)
        try restored.engine.restore()
        #expect(restored.completionSound.playbacks.isEmpty)
    }

    @Test("Canceling or skipping a timer never plays its completion sound")
    func onlySoundsOnNaturalCompletion() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus()
        try harness.engine.cancel()
        try harness.engine.startShortBreak()
        try harness.engine.skipBreak()
        #expect(harness.completionSound.playbacks.isEmpty)
    }

    @Test("Changing a running timer's sound replaces its alert at the original finish time")
    func updatesRunningAlert() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        let finish = session.endDate
        harness.clock.advance(by: 100)

        try harness.engine.setTimerSound(.gentleBell)

        #expect(harness.settings.timerSound == .gentleBell)
        #expect(session.endDate == finish)
        #expect(harness.engine.remainingTime == 1_400)
        #expect(harness.notifications.schedules.count == 2)
        #expect(harness.notifications.schedules.last?.id == session.id)
        #expect(harness.notifications.schedules.last?.date == finish)
        #expect(harness.notifications.schedules.last?.sound == .gentleBell)
    }

    @Test("Silent removes the sound while preserving the completion notification")
    func silencesRunningAlert() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        try harness.engine.setTimerSound(.silent)

        #expect(!harness.settings.soundEnabled)
        #expect(harness.notifications.schedules.last?.soundEnabled == false)
        #expect(harness.notifications.schedules.last?.sound == .silent)
        #expect(harness.notifications.schedules.last?.id == session.id)
        #expect(harness.notifications.cancellations.isEmpty)
    }

    @Test("A paused timer uses the new sound only when it resumes")
    func updatesPausedTimerOnResume() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 100)
        try harness.engine.pause()
        try harness.engine.setTimerSound(.softPulse)

        #expect(harness.notifications.schedules.count == 1)
        #expect(session.state == .paused)
        #expect(harness.engine.remainingTime == 1_400)

        try harness.engine.resume()
        #expect(harness.notifications.schedules.last?.sound == .softPulse)
    }

    @Test("A sound change does not schedule an alert when notifications are disabled")
    func respectsNotificationPreference() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(notificationsEnabled: false))
        try harness.engine.startFocus()
        try harness.engine.setTimerSound(.clearChime)
        #expect(harness.notifications.schedules.isEmpty)
    }

    @Test("Sound changes at the finish time preserve the already-due alert")
    func preservesDueAlert() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 60))
        try harness.engine.startFocus()
        harness.clock.advance(by: 60)
        try harness.engine.setTimerSound(.clearChime)

        #expect(harness.notifications.schedules.count == 1)
        #expect(harness.notifications.cancellations.isEmpty)
    }

    @Test("A failed save restores the sound preference and leaves the pending alert intact")
    func rollsBackFailedSave() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus()
        harness.store.saveError = CocoaError(.fileWriteUnknown)

        #expect(throws: CocoaError.self) {
            try harness.engine.setTimerSound(.silent)
        }
        #expect(harness.settings.timerSound == .systemDefault)
        #expect(harness.settings.soundEnabled)
        #expect(harness.notifications.schedules.count == 1)
        #expect(harness.notifications.cancellations.isEmpty)
    }

    @Test("Disabling and enabling notifications updates the current timer without changing its finish time")
    func togglesRunningNotifications() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(timerSound: .clearChime))
        let session = try harness.engine.startFocus()
        let finish = session.endDate

        try harness.engine.setNotificationsEnabled(false)
        #expect(harness.notifications.cancellations == [session.id])
        try harness.engine.setNotificationsEnabled(true)
        #expect(harness.notifications.schedules.last?.date == finish)
        #expect(harness.notifications.schedules.last?.sound == .clearChime)
        #expect(session.endDate == finish)
    }
}
