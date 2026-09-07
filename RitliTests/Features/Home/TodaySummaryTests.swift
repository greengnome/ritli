import Foundation
import Testing
@testable import Ritli

struct TodaySummaryTests {
    @Test("Summary derives today's metrics from raw sessions and tasks")
    func derivesTodayMetrics() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!

        let completedFocus = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: now,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500
        )
        let cancelledFocus = FocusSession(
            kind: .focus,
            state: .cancelled,
            startedAt: now,
            plannedDuration: 1_500,
            actualActiveDuration: 600
        )
        let completedBreak = FocusSession(
            kind: .shortBreak,
            state: .completed,
            startedAt: now,
            plannedDuration: 300,
            actualActiveDuration: 300
        )
        let oldFocus = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: yesterday,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500
        )
        let completedToday = FocusTask(
            title: "Today",
            completedAt: now
        )
        let completedYesterday = FocusTask(
            title: "Yesterday",
            completedAt: yesterday
        )

        let summary = TodaySummary(
            sessions: [completedFocus, cancelledFocus, completedBreak, oldFocus],
            tasks: [completedToday, completedYesterday, FocusTask(title: "Open")],
            now: now,
            calendar: calendar
        )

        #expect(summary.completedSessions == 1)
        #expect(summary.focusTime == 2_100)
        #expect(summary.completedTasks == 1)
    }
}
