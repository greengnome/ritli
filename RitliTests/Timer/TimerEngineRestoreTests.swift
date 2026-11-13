import Foundation
import Testing
@testable import Ritli

/// Relaunch and returning to the foreground: reconciling what happened
/// while the app was away, without replaying alerts.
@MainActor
struct TimerEngineRestoreTests {
    private let start = Date(timeIntervalSince1970: 20_000)

    private func runningFocus(duration: TimeInterval = 60) -> FocusSession {
        FocusSession(
            kind: .focus,
            startedAt: start,
            plannedDuration: duration,
            endDate: start.addingTimeInterval(duration)
        )
    }

    @Test("Restore resumes running and paused sessions and clears a stale Live Activity")
    func restoresActiveSessions() throws {
        let running = runningFocus(duration: 1_500)
        let runningHarness = TimerEngineHarness(
            startDate: start.addingTimeInterval(100),
            sessions: [running]
        )
        let paused = FocusSession(
            kind: .longBreak,
            state: .paused,
            startedAt: start,
            plannedDuration: 900,
            pausedRemainingTime: 450
        )
        let pausedHarness = TimerEngineHarness(
            startDate: start.addingTimeInterval(100),
            sessions: [paused]
        )
        let emptyHarness = TimerEngineHarness()

        try runningHarness.engine.restore()
        try pausedHarness.engine.restore()
        try emptyHarness.engine.restore()

        #expect(runningHarness.engine.currentSession === running)
        #expect(runningHarness.notifications.pending[running.id]?.date == running.endDate)
        #expect(runningHarness.liveActivities.lastDescriptor?.attributes.sessionID == running.id)
        #expect(pausedHarness.notifications.pending.isEmpty)
        #expect(
            pausedHarness.liveActivities.lastDescriptor?.contentState.phase
                == .paused(remainingTime: 450)
        )
        #expect(emptyHarness.liveActivities.events == [.ended])
    }

    @Test("An overdue session is finalized at its end date without sound or haptics")
    func catchesUpSilently() throws {
        let session = runningFocus()
        let harness = TimerEngineHarness(
            startDate: start.addingTimeInterval(600),
            settings: PomodoroSettings(focusDuration: 60, timerSound: .gentleBell),
            sessions: [session]
        )

        try harness.engine.restore()

        #expect(session.state == .completed)
        #expect(session.finishedAt == start.addingTimeInterval(60))
        #expect(harness.cycle.completedFocusesInCycle == 1)
        #expect(harness.liveActivities.events == [.ended])
        #expect(harness.completionSound.playbacks.isEmpty)
        #expect(harness.feedback.events.isEmpty)
    }

    @Test("Returning while the auto-started break is still due continues it from the real start")
    func catchUpContinuesRunningFollowUp() throws {
        let session = runningFocus()
        let harness = TimerEngineHarness(
            startDate: start.addingTimeInterval(60 + 120),
            settings: PomodoroSettings(
                focusDuration: 60,
                shortBreakDuration: 300,
                autoStartBreaks: true
            ),
            sessions: [session]
        )

        try harness.engine.restore()

        let breakSession = try #require(harness.engine.currentSession)
        #expect(breakSession.id == FocusSession.followUpID(after: session.id))
        #expect(breakSession.kind == .shortBreak)
        #expect(breakSession.state == .running)
        #expect(breakSession.startedAt == start.addingTimeInterval(60))
        #expect(harness.engine.remainingTime == 180)
        #expect(harness.notifications.pending[breakSession.id]?.date == breakSession.endDate)
        #expect(harness.feedback.events.isEmpty)

        try harness.engine.restore()
        #expect(harness.cycle.completedFocusesInCycle == 1)
        #expect(harness.store.sessions.count == 2)
    }

    @Test("A follow-up that also ran out is recorded, and nothing further auto-starts")
    func catchUpStopsAfterOnePhase() throws {
        let session = runningFocus()
        let harness = TimerEngineHarness(
            startDate: start.addingTimeInterval(12 * 3_600),
            settings: PomodoroSettings(
                focusDuration: 60,
                shortBreakDuration: 300,
                autoStartBreaks: true,
                autoStartFocus: true
            ),
            sessions: [session]
        )

        try harness.engine.restore()

        #expect(harness.store.sessions.count == 2)
        let breakSession = try #require(harness.engine.currentSession)
        #expect(breakSession.kind == .shortBreak)
        #expect(breakSession.state == .completed)
        #expect(breakSession.finishedAt == start.addingTimeInterval(60 + 300))
        #expect(!harness.engine.hasActiveSession)
        #expect(harness.cycle.nextSuggestedKind == .focus)
        #expect(harness.liveActivities.events.last == .ended)
        #expect(harness.completionSound.playbacks.isEmpty)
    }

    @Test("The first refresh after returning catches up silently; later ones play the sound")
    func refreshCatchUpIsSilent() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 1, timerSound: .gentleBell))
        try harness.engine.startFocus()
        harness.clock.advance(by: 10)

        try harness.engine.refresh(catchingUp: true)
        #expect(harness.completionSound.playbacks.isEmpty)

        let session = try harness.engine.startFocus()
        try harness.completeCurrent()
        #expect(harness.completionSound.playbacks.map(\.id) == [session.id])
    }

    @Test("Restore forgets a remembered task that is already finished")
    func clearsExhaustedPreferredTask() throws {
        let task = FocusTask(title: "Done", estimatedPomodoros: 1)
        let completed = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: start,
            finishedAt: start.addingTimeInterval(60),
            plannedDuration: 60,
            task: task
        )
        task.sessions.append(completed)
        let harness = TimerEngineHarness(
            cycle: PomodoroCycleState(preferredFocusTask: task),
            sessions: [completed]
        )

        try harness.engine.restore()

        #expect(harness.cycle.preferredFocusTask == nil)
        #expect(harness.store.saveCount == 1)
    }

    @Test("Releasing a finished session leaves an active one alone")
    func releasesOnlyFinishedSessions() throws {
        let harness = TimerEngineHarness()
        try harness.engine.startFocus()
        harness.engine.releaseFinishedSession()
        #expect(harness.engine.hasActiveSession)

        try harness.engine.cancel()
        harness.engine.releaseFinishedSession()
        #expect(harness.engine.currentSession == nil)
    }
}
