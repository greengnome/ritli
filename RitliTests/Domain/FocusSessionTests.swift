import Foundation
import Testing
@testable import Ritli

struct FocusSessionTests {
    @Test("Terminal states are explicitly identified", arguments: [
        (SessionState.running, false),
        (SessionState.paused, false),
        (SessionState.completed, true),
        (SessionState.cancelled, true),
        (SessionState.skipped, true),
    ])
    func terminalState(state: SessionState, expected: Bool) {
        #expect(state.isTerminal == expected)
    }

    @Test("A session snapshots its resolved category")
    func snapshotsCategory() {
        let category = FocusCategory(name: "Work", colorToken: "orange")
        let task = FocusTask(title: "Roadmap", category: category)
        let session = FocusSession(
            kind: .focus,
            plannedDuration: 1_500,
            task: task,
            timeZone: TimeZone(identifier: "UTC")!
        )

        #expect(session.category === category)
        #expect(session.categoryNameSnapshot == "Work")
        #expect(session.categoryColorTokenSnapshot == "orange")
        #expect(session.timeZoneIdentifier == "GMT")
    }

    @Test("Durations cannot start negative")
    func normalizesDurations() {
        let session = FocusSession(
            kind: .focus,
            plannedDuration: -10,
            actualActiveDuration: -5,
            totalPausedDuration: -2
        )

        #expect(session.plannedDuration == 0)
        #expect(session.actualActiveDuration == 0)
        #expect(session.totalPausedDuration == 0)
    }
}
