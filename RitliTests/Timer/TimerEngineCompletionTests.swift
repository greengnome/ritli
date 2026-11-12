import Foundation
import Testing
@testable import Ritli

/// Natural completion, the Pomodoro cycle, and auto-start.
@MainActor
struct TimerEngineCompletionTests {
    private static func shortSettings() -> PomodoroSettings {
        PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 30,
            longBreakDuration: 90,
            longBreakEvery: 4,
            timerSound: .clearChime
        )
    }

    @Test("Natural completion finishes once with every side effect", arguments: [
        (SessionKind.focus, 0, SessionKind.shortBreak, 1),
        (SessionKind.shortBreak, 1, SessionKind.focus, 1),
        (SessionKind.longBreak, 4, SessionKind.focus, 0),
    ])
    func completesOnce(
        kind: SessionKind,
        completedBefore: Int,
        expectedNext: SessionKind,
        expectedCompleted: Int
    ) throws {
        let harness = TimerEngineHarness(
            settings: Self.shortSettings(),
            cycle: PomodoroCycleState(completedFocusesInCycle: completedBefore)
        )
        let session = try harness.start(kind)
        let endDate = try #require(session.endDate)
        harness.clock.advance(by: session.plannedDuration)
        harness.log.reset()

        #expect(try harness.engine.refresh())

        #expect(session.state == .completed)
        #expect(session.finishedAt == endDate)
        #expect(session.actualActiveDuration == session.plannedDuration)
        #expect(harness.cycle.nextSuggestedKind == expectedNext)
        #expect(harness.cycle.completedFocusesInCycle == expectedCompleted)
        #expect(harness.liveActivities.events.last == .ended)
        // The due alert stays deliverable; only the unused follow-up is withdrawn.
        #expect(harness.notifications.pending[session.id] != nil)
        #expect(harness.log.calls == [
            .save, .liveActivity, .feedback(.completed), .sound, .cancelNotification,
        ])
        #expect(harness.completionSound.playbacks == [
            .init(id: session.id, sound: .clearChime, hasScheduledNotification: true),
        ])

        #expect(try !harness.engine.refresh())
        #expect(harness.completionSound.playbacks.count == 1)
        #expect(harness.cycle.completedFocusesInCycle == expectedCompleted)
    }

    @Test("The completion sound plays even with notifications and haptics off")
    func soundsWithoutNotificationsOrHaptics() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(
            focusDuration: 1,
            timerSound: .gentleBell,
            hapticsEnabled: false,
            notificationsEnabled: false
        ))
        let session = try harness.engine.startFocus()

        try harness.completeCurrent()

        #expect(harness.completionSound.playbacks == [
            .init(id: session.id, sound: .gentleBell, hasScheduledNotification: false),
        ])
        #expect(harness.notifications.schedules.isEmpty)
        #expect(harness.feedback.events.isEmpty)
    }

    @Test("A full cycle earns a long break after the configured focus count, then resets")
    func runsFullCycle() throws {
        let harness = TimerEngineHarness(settings: Self.shortSettings())

        for round in 1...4 {
            try harness.engine.startFocus()
            try harness.completeCurrent()
            #expect(harness.cycle.completedFocusesInCycle == round)
            if round < 4 {
                #expect(harness.cycle.nextSuggestedKind == .shortBreak)
                try harness.engine.startShortBreak()
                try harness.completeCurrent()
                #expect(harness.cycle.nextSuggestedKind == .focus)
            }
        }
        #expect(harness.cycle.nextSuggestedKind == .longBreak)

        let longBreak = try harness.engine.startLongBreak()
        #expect(longBreak.plannedDuration == 90)
        try harness.completeCurrent()

        #expect(harness.cycle.completedFocusesInCycle == 0)
        #expect(harness.cycle.nextSuggestedKind == .focus)
        #expect(harness.cycle.routineSnapshot == nil)
    }

    @Test("Only completed focus sessions count toward a task's estimate")
    func completesTaskAfterFinalFocus() throws {
        let task = FocusTask(title: "Proposal", estimatedPomodoros: 2)
        let harness = TimerEngineHarness(settings: Self.shortSettings())

        try harness.engine.startFocus(task: task)
        harness.clock.advance(by: 30)
        try harness.engine.cancel()
        #expect(task.completedPomodoros == 0)

        try harness.engine.startFocus(task: task)
        try harness.completeCurrent()
        try harness.engine.startShortBreak()
        try harness.completeCurrent()
        #expect(task.completedPomodoros == 1)
        #expect(!task.isCompleted)

        try harness.engine.startFocus(task: task)
        try harness.completeCurrent()
        #expect(task.completedPomodoros == 2)
        #expect(task.completedAt == harness.clock.now)
        #expect(harness.cycle.preferredFocusTask == nil)
    }

    @Test("Auto-start begins the next phase at the previous end, with its own alert", arguments: [
        (SessionKind.focus, 0, SessionKind.shortBreak),
        (SessionKind.focus, 3, SessionKind.longBreak),
        (SessionKind.shortBreak, 1, SessionKind.focus),
        (SessionKind.longBreak, 4, SessionKind.focus),
    ])
    func autoStartsNextPhase(
        kind: SessionKind,
        completedBefore: Int,
        expectedNext: SessionKind
    ) throws {
        let settings = PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 30,
            longBreakDuration: 90,
            autoStartBreaks: true,
            autoStartFocus: true
        )
        let harness = TimerEngineHarness(
            settings: settings,
            cycle: PomodoroCycleState(completedFocusesInCycle: completedBefore)
        )
        let session = try harness.start(kind)
        let endDate = try #require(session.endDate)
        let followUpID = FocusSession.followUpID(after: session.id)
        let scheduledFollowUp = try #require(harness.notifications.pending[followUpID])
        #expect(scheduledFollowUp.kind == expectedNext)

        harness.clock.advance(by: session.plannedDuration + 0.4)
        try harness.engine.refresh()

        let next = try #require(harness.engine.currentSession)
        #expect(next.id == followUpID)
        #expect(next.kind == expectedNext)
        #expect(next.state == .running)
        #expect(next.startedAt == endDate)
        #expect(next.endDate == scheduledFollowUp.date)
        #expect(harness.liveActivities.lastDescriptor?.attributes.sessionID == next.id)
        #expect(harness.feedback.events.suffix(2) == [.completed, .started])
    }

    @Test("Auto-started focus keeps the selected task until its estimate is reached")
    func autoStartedFocusFollowsPreferredTask() throws {
        let task = FocusTask(title: "Ship Ritli", estimatedPomodoros: 2)
        let settings = PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 60,
            autoStartBreaks: true,
            autoStartFocus: true
        )
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.startFocus(task: task)

        try harness.completeCurrent()
        #expect(harness.engine.currentSession?.kind == .shortBreak)
        try harness.completeCurrent()
        #expect(harness.engine.currentSession?.task === task)

        try harness.completeCurrent()
        #expect(task.isCompleted)
        #expect(harness.cycle.preferredFocusTask == nil)
        try harness.completeCurrent()
        #expect(harness.engine.currentSession?.kind == .focus)
        #expect(harness.engine.currentSession?.task == nil)
    }

    @Test("A task routine freezes its focus and following break; app defaults stay live")
    func routineSnapshots() throws {
        let routine = TimerRoutine(
            name: "Writing",
            focusDuration: 60,
            shortBreakDuration: 30,
            longBreakEvery: 2,
            autoStartBreaks: true
        )
        let task = FocusTask(title: "Write chapter", timerRoutine: routine)
        let harness = TimerEngineHarness(
            settings: PomodoroSettings(focusDuration: 120, shortBreakDuration: 90),
            cycle: PomodoroCycleState(completedFocusesInCycle: 0)
        )

        let focus = try harness.engine.startFocus(task: task)
        #expect(focus.plannedDuration == 60)
        routine.shortBreakDuration = 300
        routine.autoStartBreaks = false
        try harness.completeCurrent()
        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.plannedDuration == 30)

        try harness.engine.skipBreak()
        try harness.engine.startFocus(task: task)
        try harness.completeCurrent()
        // The routine's own interval (2) earns the long break, not the app's (4).
        #expect(harness.cycle.nextSuggestedKind == .longBreak)
    }

    @Test("Without a task routine, Settings edits apply to the very next session")
    func appDefaultsApplyToNextSession() throws {
        let settings = PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 30,
            autoStartBreaks: false
        )
        let harness = TimerEngineHarness(settings: settings)

        try harness.engine.startFocus()
        try harness.completeCurrent()
        settings.shortBreakDuration = 300
        #expect(harness.engine.previewDuration(for: .shortBreak) == 300)
        #expect(try harness.engine.startShortBreak().plannedDuration == 300)

        try harness.engine.cancel()
        try harness.engine.startFocus()
        settings.autoStartBreaks = true
        harness.engine.applySettingsChanges()
        let focus = try #require(harness.engine.currentSession)
        #expect(harness.notifications.pending[FocusSession.followUpID(after: focus.id)] != nil)
        try harness.completeCurrent()
        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.state == .running)
    }

    @Test("The idle focus preview uses the selected task's routine")
    func previewUsesTaskRoutine() {
        let task = FocusTask(
            title: "Write chapter",
            timerRoutine: TimerRoutine(name: "Writing", focusDuration: 30 * 60)
        )
        let harness = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 25 * 60))

        #expect(harness.engine.previewDuration(for: .focus, task: task) == 30 * 60)
        #expect(harness.engine.previewDuration(for: .focus) == 25 * 60)
    }

    @Test("Pausing or cancelling withdraws the follow-up alert; resuming reschedules it")
    func followUpAlertTracksTheRunningSession() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 30,
            autoStartBreaks: true
        ))
        let session = try harness.engine.startFocus()
        let followUpID = FocusSession.followUpID(after: session.id)
        #expect(harness.notifications.pending[followUpID]?.date == session.endDate?.addingTimeInterval(30))

        harness.clock.advance(by: 10)
        try harness.engine.pause()
        #expect(harness.notifications.pending.isEmpty)

        harness.clock.advance(by: 100)
        try harness.engine.resume()
        #expect(harness.notifications.pending[followUpID]?.date == session.endDate?.addingTimeInterval(30))

        try harness.engine.cancel()
        #expect(harness.notifications.pending.isEmpty)
    }

    @Test("Follow-up identifiers are stable, distinct and never cycle back")
    func followUpIdentifiers() {
        let id = UUID()
        let next = FocusSession.followUpID(after: id)
        let afterNext = FocusSession.followUpID(after: next)

        #expect(FocusSession.followUpID(after: id) == next)
        #expect(Set([id, next, afterNext]).count == 3)
    }
}
