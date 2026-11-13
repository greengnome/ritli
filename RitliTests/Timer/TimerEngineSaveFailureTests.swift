import Foundation
import SwiftData
import Testing
@testable import Ritli

/// When saving fails, memory must match the store again and no alert, Live
/// Activity or sound may describe a change that was never persisted.
@MainActor
struct TimerEngineSaveFailureTests {
    @Test("A start that can't be saved leaves no session, alert or Live Activity")
    func failedStartRollsBack() throws {
        let harness = try SwiftDataTimerHarness()
        harness.store.failsNextSave = true

        #expect(throws: CocoaError.self) {
            try harness.engine.startFocus(task: nil)
        }

        #expect(harness.engine.currentSession == nil)
        #expect(!harness.engine.hasActiveSession)
        #expect(try harness.sessions().isEmpty)
        #expect(harness.notifications.schedules.isEmpty)
        #expect(harness.liveActivities.events.isEmpty)

        // The next attempt works normally.
        try harness.engine.startFocus()
        #expect(try harness.sessions().count == 1)
    }

    @Test("A pause that can't be saved keeps the session running with its alert")
    func failedPauseRollsBack() throws {
        let harness = try SwiftDataTimerHarness()
        let session = try harness.engine.startFocus()
        let endDate = session.endDate
        harness.clock.advance(by: 100)
        harness.store.failsNextSave = true

        #expect(throws: CocoaError.self) {
            try harness.engine.pause()
        }

        #expect(session.state == .running)
        #expect(session.endDate == endDate)
        #expect(session.pausedRemainingTime == nil)
        #expect(harness.notifications.pending[session.id] != nil)
        #expect(harness.liveActivities.events.count == 1)
    }

    @Test("A completion that can't be saved is retried on the next refresh")
    func failedCompletionIsRetried() throws {
        let harness = try SwiftDataTimerHarness(
            settings: PomodoroSettings(focusDuration: 60)
        )
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 60)
        harness.store.failsNextSave = true

        #expect(throws: CocoaError.self) {
            try harness.engine.refresh()
        }
        #expect(session.state == .running)
        #expect(harness.cycle.completedFocusesInCycle == 0)

        #expect(try harness.engine.refresh())
        #expect(session.state == .completed)
        #expect(harness.cycle.completedFocusesInCycle == 1)
    }
}
