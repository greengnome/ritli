import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerEngineLiveActivityTests {
    @Test("Starting, pausing, and resuming synchronize the same session")
    func synchronizesRunningLifecycle() throws {
        let harness = TimerEngineHarness(
            settings: PomodoroSettings(showTaskTitlesOnLockScreen: true)
        )
        let task = FocusTask(title: "Prepare release")

        let session = try harness.engine.startFocus(task: task)
        harness.clock.advance(by: 100)
        try harness.engine.pause()
        harness.clock.advance(by: 50)
        try harness.engine.resume()

        #expect(harness.liveActivities.events.count == 3)
        #expect(activeDescriptor(in: harness.liveActivities.events[0])?.attributes.sessionID == session.id)
        #expect(activeDescriptor(in: harness.liveActivities.events[0])?.contentState.taskTitle == "Prepare release")
        #expect(activeDescriptor(in: harness.liveActivities.events[1])?.contentState.phase == .paused(remainingTime: 1_400))
        #expect(
            activeDescriptor(in: harness.liveActivities.events[2])?.contentState.phase
                == .running(endDate: harness.clock.now.addingTimeInterval(1_400))
        )
    }

    @Test("Changing task-title privacy refreshes a running Live Activity")
    func refreshesTaskTitlePrivacy() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus(
            task: FocusTask(title: "Confidential plan")
        )

        try harness.engine.setShowTaskTitlesOnLockScreen(true)
        try harness.engine.setShowTaskTitlesOnLockScreen(false)

        #expect(harness.liveActivities.events.count == 3)
        #expect(activeDescriptor(in: harness.liveActivities.events[0])?.contentState.taskTitle == nil)
        #expect(activeDescriptor(in: harness.liveActivities.events[1])?.contentState.taskTitle == "Confidential plan")
        #expect(activeDescriptor(in: harness.liveActivities.events[2])?.contentState.taskTitle == nil)
    }

    @Test("Cancelling or skipping ends the active Live Activity")
    func synchronizesTerminalCommands() throws {
        let focusHarness = TimerEngineHarness()
        try focusHarness.engine.startFocus()
        try focusHarness.engine.cancel()

        let breakHarness = TimerEngineHarness()
        try breakHarness.engine.startShortBreak()
        try breakHarness.engine.skipBreak()

        #expect(focusHarness.liveActivities.events.last == .ended)
        #expect(breakHarness.liveActivities.events.last == .ended)
    }

    @Test("Natural completion ends the current Live Activity")
    func synchronizesCompletion() throws {
        let settings = PomodoroSettings(focusDuration: 60)
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.refresh()

        #expect(harness.liveActivities.events.count == 2)
        #expect(harness.liveActivities.events.last == .ended)
    }

    @Test("Auto-start completion replaces the finished activity with the break")
    func synchronizesAutoStart() throws {
        let settings = PomodoroSettings(
            focusDuration: 60,
            autoStartBreaks: true
        )
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.refresh()

        #expect(harness.liveActivities.events.count == 3)
        #expect(harness.liveActivities.events[1] == .ended)
        #expect(activeDescriptor(in: harness.liveActivities.events[2])?.attributes.kind == .shortBreak)
    }

    @Test("Restore reconciles running, paused, and missing sessions")
    func synchronizesRestore() throws {
        let start = Date(timeIntervalSince1970: 20_000)
        let runningSession = FocusSession(
            kind: .focus,
            startedAt: start,
            plannedDuration: 1_500,
            endDate: start.addingTimeInterval(1_500)
        )
        let runningHarness = TimerEngineHarness(
            startDate: start.addingTimeInterval(100),
            sessions: [runningSession]
        )
        let pausedSession = FocusSession(
            kind: .longBreak,
            state: .paused,
            startedAt: start,
            plannedDuration: 900,
            pausedRemainingTime: 450
        )
        let pausedHarness = TimerEngineHarness(
            startDate: start.addingTimeInterval(100),
            sessions: [pausedSession]
        )
        let emptyHarness = TimerEngineHarness()

        try runningHarness.engine.restore()
        try pausedHarness.engine.restore()
        try emptyHarness.engine.restore()

        #expect(activeDescriptor(in: runningHarness.liveActivities.events.last)?.attributes.sessionID == runningSession.id)
        #expect(activeDescriptor(in: pausedHarness.liveActivities.events.last)?.contentState.phase == .paused(remainingTime: 450))
        #expect(emptyHarness.liveActivities.events == [.ended])
    }

    @Test("Restoring an overdue session ends any orphaned Live Activity")
    func synchronizesOverdueRestore() throws {
        let start = Date(timeIntervalSince1970: 30_000)
        let session = FocusSession(
            kind: .focus,
            startedAt: start,
            plannedDuration: 60,
            endDate: start.addingTimeInterval(60)
        )
        let harness = TimerEngineHarness(
            startDate: start.addingTimeInterval(600),
            sessions: [session]
        )

        try harness.engine.restore()

        #expect(session.state == .completed)
        #expect(harness.liveActivities.events == [.ended])
    }

    private func activeDescriptor(
        in event: TimerLiveActivityCoordinatorSpy.Event?
    ) -> TimerLiveActivityDescriptor? {
        guard case let .active(descriptor) = event else { return nil }
        return descriptor
    }
}
