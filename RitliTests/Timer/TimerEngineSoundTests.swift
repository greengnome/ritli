import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerEngineSoundTests {
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
