import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerEngineRestoreTests {
    @Test("Restore clears a persisted task whose estimate is already complete")
    func clearsExhaustedPreferredTask() throws {
        let task = FocusTask(title: "Ship Ritli", estimatedPomodoros: 1)
        task.sessions = [
            FocusSession(
                kind: .focus,
                state: .completed,
                plannedDuration: 60,
                task: task
            )
        ]
        let cycle = PomodoroCycleState(preferredFocusTask: task)
        let harness = TimerEngineHarness(cycle: cycle)

        try harness.engine.restore()

        #expect(harness.cycle.preferredFocusTask == nil)
        #expect(harness.store.saveCount == 1)
    }

    @Test("Restoring an overdue session finalizes it and applies auto-start")
    func finalizesOverdueSessionAndAutoStarts() throws {
        let start = Date(timeIntervalSince1970: 20_000)
        let session = FocusSession(
            kind: .focus,
            startedAt: start,
            plannedDuration: 60,
            endDate: start.addingTimeInterval(60)
        )
        let settings = PomodoroSettings(
            focusDuration: 60,
            autoStartBreaks: true
        )
        let harness = TimerEngineHarness(
            startDate: start.addingTimeInterval(600),
            settings: settings,
            sessions: [session]
        )

        try harness.engine.restore()

        #expect(session.state == .completed)
        #expect(session.finishedAt == start.addingTimeInterval(60))
        #expect(harness.store.sessions.count == 2)
        #expect(harness.cycle.completedFocusesInCycle == 1)
        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.state == .running)

        try harness.engine.restore()
        #expect(harness.cycle.completedFocusesInCycle == 1)
        #expect(harness.store.sessions.count == 2)
    }

    @Test("Restoring a running session reschedules its notification")
    func restoresRunningSession() throws {
        let start = Date(timeIntervalSince1970: 30_000)
        let end = start.addingTimeInterval(1_500)
        let session = FocusSession(
            kind: .focus,
            startedAt: start,
            plannedDuration: 1_500,
            endDate: end
        )
        let harness = TimerEngineHarness(
            startDate: start.addingTimeInterval(100),
            sessions: [session]
        )

        try harness.engine.restore()

        #expect(harness.engine.currentSession === session)
        #expect(harness.engine.remainingTime == 1_400)
        #expect(harness.notifications.schedules == [
            .init(
                id: session.id,
                kind: .focus,
                date: end,
                soundEnabled: true
            )
        ])
    }
}
