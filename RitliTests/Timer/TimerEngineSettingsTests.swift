import Foundation
import Testing
@testable import Ritli

/// Preference changes that affect a timer already in flight.
@MainActor
struct TimerEngineSettingsTests {
    @Test("Changing the sound replaces the running alert at its original finish time")
    func soundChangeReplacesAlert() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        let finish = session.endDate
        harness.clock.advance(by: 100)

        try harness.engine.setTimerSound(.gentleBell)

        #expect(harness.settings.timerSound == .gentleBell)
        #expect(session.endDate == finish)
        #expect(harness.notifications.pending[session.id]?.date == finish)
        #expect(harness.notifications.pending[session.id]?.sound == .gentleBell)

        try harness.engine.setTimerSound(.silent)
        #expect(!harness.settings.soundEnabled)
        #expect(harness.notifications.pending[session.id]?.soundEnabled == false)
        #expect(harness.notifications.pending[session.id]?.sound == .silent)
    }

    @Test("A paused timer picks up a new sound when it resumes")
    func pausedTimerUsesNewSoundOnResume() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 100)
        try harness.engine.pause()

        try harness.engine.setTimerSound(.softPulse)
        #expect(harness.notifications.pending.isEmpty)

        try harness.engine.resume()
        #expect(harness.notifications.pending[session.id]?.sound == .softPulse)
    }

    @Test("Sound changes at the finish time keep the already-due alert")
    func keepsDueAlert() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 60))
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.setTimerSound(.clearChime)

        #expect(harness.notifications.schedules.map(\.id) == [session.id])
        #expect(harness.notifications.pending[session.id] != nil)
    }

    @Test("Toggling notifications withdraws and restores the running alerts")
    func togglesRunningNotifications() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(
            shortBreakDuration: 300,
            autoStartBreaks: true,
            timerSound: .clearChime
        ))
        let session = try harness.engine.startFocus()
        let finish = session.endDate

        try harness.engine.setNotificationsEnabled(false)
        #expect(harness.notifications.pending.isEmpty)

        try harness.engine.setNotificationsEnabled(true)
        #expect(harness.notifications.pending[session.id]?.date == finish)
        #expect(harness.notifications.pending[session.id]?.sound == .clearChime)
        #expect(harness.notifications.pending.count == 2)
        #expect(session.endDate == finish)
    }

    @Test("Showing task titles on the Lock Screen refreshes the Live Activity")
    func refreshesTaskTitlePrivacy() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus(task: FocusTask(title: "Confidential plan"))
        #expect(harness.liveActivities.lastDescriptor?.contentState.taskTitle == nil)

        try harness.engine.setShowTaskTitlesOnLockScreen(true)
        #expect(harness.liveActivities.lastDescriptor?.contentState.taskTitle == "Confidential plan")

        try harness.engine.setShowTaskTitlesOnLockScreen(false)
        #expect(harness.liveActivities.lastDescriptor?.contentState.taskTitle == nil)
    }

    @Test("Choosing a task during a break re-plans the auto-started focus alert")
    func selectingTaskUpdatesFollowUp() throws {
        let task = FocusTask(
            title: "Deep work",
            timerRoutine: TimerRoutine(name: "Long", focusDuration: 50 * 60)
        )
        let harness = TimerEngineHarness(settings: PomodoroSettings(
            focusDuration: 25 * 60,
            shortBreakDuration: 300,
            autoStartFocus: true
        ))
        let breakSession = try harness.engine.startShortBreak()
        let followUpID = FocusSession.followUpID(after: breakSession.id)
        #expect(harness.notifications.pending[followUpID]?.date == breakSession.endDate?.addingTimeInterval(25 * 60))

        try harness.engine.selectFocusTask(task)

        #expect(harness.cycle.preferredFocusTask === task)
        #expect(harness.notifications.pending[followUpID]?.date == breakSession.endDate?.addingTimeInterval(50 * 60))
    }

    @Test("A failed save restores the previous preference and leaves alerts alone", arguments: [
        "sound", "notifications", "lockScreen", "task",
    ])
    func rollsBackFailedPreferenceSave(setting: String) throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus()
        let schedulesBefore = harness.notifications.schedules.count
        let eventsBefore = harness.liveActivities.events.count
        harness.store.saveError = CocoaError(.fileWriteUnknown)

        #expect(throws: CocoaError.self) {
            switch setting {
            case "sound": try harness.engine.setTimerSound(.silent)
            case "notifications": try harness.engine.setNotificationsEnabled(false)
            case "lockScreen": try harness.engine.setShowTaskTitlesOnLockScreen(true)
            default: try harness.engine.selectFocusTask(FocusTask(title: "Other"))
            }
        }

        #expect(harness.settings.timerSound == .systemDefault)
        #expect(harness.settings.soundEnabled)
        #expect(harness.settings.notificationsEnabled)
        #expect(!harness.settings.showTaskTitlesOnLockScreen)
        #expect(harness.cycle.preferredFocusTask == nil)
        #expect(harness.store.rollbackCount == 1)
        #expect(harness.notifications.schedules.count == schedulesBefore)
        #expect(harness.liveActivities.events.count == eventsBefore)
    }
}
