import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerEngineLifecycleTests {
    @Test("Starting focus snapshots duration, task, and end date")
    func startsFocus() throws {
        let harness = TimerEngineHarness()
        let task = FocusTask(title: "Project roadmap")

        let session = try harness.engine.startFocus(task: task)

        #expect(session.state == .running)
        #expect(session.kind == .focus)
        #expect(session.task === task)
        #expect(session.plannedDuration == 1_500)
        #expect(session.endDate == harness.startDate.addingTimeInterval(1_500))
        #expect(harness.store.sessions.count == 1)
        #expect(harness.notifications.schedules == [
            .init(
                id: session.id,
                kind: .focus,
                date: session.endDate!,
                soundEnabled: true
            )
        ])
    }

    @Test("Changing settings never changes the running session")
    func runningSessionKeepsDurationSnapshot() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()

        harness.settings.focusDuration = 3_000
        harness.clock.advance(by: 100)

        #expect(session.plannedDuration == 1_500)
        #expect(harness.engine.remainingTime == 1_400)
    }

    @Test("Disabled notifications do not schedule session alerts")
    func respectsDisabledNotifications() throws {
        let settings = PomodoroSettings(notificationsEnabled: false)
        let harness = TimerEngineHarness(settings: settings)

        try harness.engine.startFocus()

        #expect(harness.notifications.schedules.isEmpty)
    }

    @Test("Notification preference changes persist through the timer store")
    func persistsNotificationPreference() throws {
        let harness = TimerEngineHarness()

        try harness.engine.setNotificationsEnabled(false)

        #expect(!harness.settings.notificationsEnabled)
        #expect(harness.store.saveCount == 1)
    }

    @Test("Disabled sounds schedule a silent notification")
    func respectsDisabledSounds() throws {
        let settings = PomodoroSettings(soundEnabled: false)
        let harness = TimerEngineHarness(settings: settings)

        try harness.engine.startFocus()

        #expect(harness.notifications.schedules.first?.soundEnabled == false)
    }

    @Test("Natural completion keeps the due notification available for delivery")
    func completionDoesNotCancelDueNotification() throws {
        let settings = PomodoroSettings(focusDuration: 60)
        let harness = TimerEngineHarness(settings: settings)
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.refresh()

        #expect(session.state == .completed)
        #expect(!harness.notifications.cancellations.contains(session.id))
    }

    @Test("Haptic feedback follows the user preference")
    func respectsHapticPreference() throws {
        let enabledHarness = TimerEngineHarness()
        try enabledHarness.engine.startFocus()
        try enabledHarness.engine.pause()
        #expect(enabledHarness.feedback.events == [.started, .paused])

        let disabledHarness = TimerEngineHarness(
            settings: PomodoroSettings(hapticsEnabled: false)
        )
        try disabledHarness.engine.startFocus()
        try disabledHarness.engine.pause()
        #expect(disabledHarness.feedback.events.isEmpty)
    }

    @Test("A second session cannot start while one is active")
    func rejectsConcurrentSession() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus()

        #expect(throws: TimerEngineError.activeSessionExists) {
            try harness.engine.startShortBreak()
        }
    }

    @Test("Pause and resume exclude paused time from the countdown")
    func pausesAndResumes() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 100)

        try harness.engine.pause()
        #expect(session.state == .paused)
        #expect(session.pausedRemainingTime == 1_400)
        #expect(session.actualActiveDuration == 100)
        #expect(harness.notifications.cancellations.last == session.id)

        harness.clock.advance(by: 500)
        #expect(harness.engine.remainingTime == 1_400)

        try harness.engine.resume()
        #expect(session.state == .running)
        #expect(session.totalPausedDuration == 500)
        #expect(session.endDate == harness.clock.now.addingTimeInterval(1_400))
        #expect(harness.notifications.schedules.count == 2)
    }

    @Test("Cancelling records active time without advancing the cycle")
    func cancelsSession() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 125)

        try harness.engine.cancel()

        #expect(session.state == .cancelled)
        #expect(session.finishedAt == harness.clock.now)
        #expect(session.actualActiveDuration == 125)
        #expect(harness.engine.progress == 125.0 / 1_500.0)
        #expect(harness.cycle.completedFocusesInCycle == 0)
        #expect(harness.cycle.nextSuggestedKind == .focus)
    }

    @Test("Cancelling while paused excludes the paused interval from active time")
    func cancelsPausedSession() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 100)
        try harness.engine.pause()
        harness.clock.advance(by: 500)

        try harness.engine.cancel()

        #expect(session.state == .cancelled)
        #expect(session.actualActiveDuration == 100)
        #expect(session.totalPausedDuration == 500)
    }

    @Test("A late pause completes the expired session without pausing an auto-started break")
    func latePauseOnlyCompletesExpiredSession() throws {
        let settings = PomodoroSettings(
            focusDuration: 60,
            autoStartBreaks: true
        )
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.pause()

        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.state == .running)
    }

    @Test("A focus session cannot be skipped")
    func rejectsSkippingFocus() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus()

        #expect(throws: TimerEngineError.focusSessionCannotBeSkipped) {
            try harness.engine.skipBreak()
        }
    }
}
