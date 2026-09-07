import Foundation
import Testing
@testable import Ritli

@MainActor
struct StatsCalculatorTests {
    @Test("Metrics distinguish active focus time, completed sessions, and tasks")
    func calculatesIndependentMetrics() {
        let completed = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 15, 9),
            activeDuration: 1_500
        )
        let cancelled = focusSession(
            state: .cancelled,
            startedAt: date(2026, 8, 15, 11),
            activeDuration: 840
        )
        let breakSession = FocusSession(
            kind: .shortBreak,
            state: .completed,
            startedAt: date(2026, 8, 15, 12),
            plannedDuration: 300,
            actualActiveDuration: 300
        )
        let previous = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 14, 9),
            activeDuration: 1_200
        )
        let completedTask = FocusTask(
            title: "Today",
            completedAt: date(2026, 8, 15, 13)
        )
        let previousTask = FocusTask(
            title: "Yesterday",
            completedAt: date(2026, 8, 14, 13)
        )

        let snapshot = calculator.snapshot(
            sessions: [completed, cancelled, breakSession, previous],
            tasks: [completedTask, previousTask, FocusTask(title: "Active")],
            period: .day,
            now: date(2026, 8, 15, 18)
        )

        #expect(snapshot.current.focusTime == 2_340)
        #expect(snapshot.current.completedSessions == 1)
        #expect(snapshot.current.completedTasks == 1)
        #expect(snapshot.previous.focusTime == 1_200)
        #expect(snapshot.previous.completedSessions == 1)
        #expect(snapshot.previous.completedTasks == 1)
        #expect(snapshot.focusTimeComparison == .change(percent: 95))
        #expect(snapshot.completedSessionsComparison == .unchanged)
    }

    @Test("A nonzero metric with no previous value is marked new")
    func handlesZeroPreviousValue() {
        let session = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 15, 9),
            activeDuration: 1_500
        )

        let snapshot = calculator.snapshot(
            sessions: [session],
            tasks: [],
            period: .day,
            now: date(2026, 8, 15, 18)
        )

        #expect(snapshot.focusTimeComparison == .new)
        #expect(snapshot.completedSessionsComparison == .new)
        #expect(snapshot.completedTasksComparison == .unavailable)
    }

    @Test("Category shares use focus time and historical snapshots")
    func calculatesCategoryShares() {
        let work = FocusCategory(name: "Work", colorToken: "coral")
        let study = FocusCategory(name: "Study", colorToken: "blue")
        let sessions = [
            focusSession(
                state: .completed,
                startedAt: date(2026, 8, 15, 9),
                activeDuration: 1_200,
                category: work
            ),
            focusSession(
                state: .cancelled,
                startedAt: date(2026, 8, 15, 11),
                activeDuration: 600,
                category: study
            ),
            focusSession(
                state: .cancelled,
                startedAt: date(2026, 8, 15, 12),
                activeDuration: 200
            )
        ]
        work.name = "Renamed later"

        let snapshot = calculator.snapshot(
            sessions: sessions,
            tasks: [],
            period: .day,
            now: date(2026, 8, 15, 18)
        )

        #expect(snapshot.categories.map(\.name) == ["Work", "Study", "Uncategorized"])
        #expect(snapshot.categories.map(\.focusTime) == [1_200, 600, 200])
        #expect(snapshot.categories.map(\.fraction) == [0.6, 0.3, 0.1])
    }

    @Test("Chart buckets aggregate sessions by their start date")
    func buildsBuckets() {
        let sessions = [
            focusSession(
                state: .completed,
                startedAt: date(2026, 8, 15, 9, 15),
                activeDuration: 1_500
            ),
            focusSession(
                state: .cancelled,
                startedAt: date(2026, 8, 15, 9, 45),
                activeDuration: 300
            )
        ]

        let snapshot = calculator.snapshot(
            sessions: sessions,
            tasks: [],
            period: .day,
            now: date(2026, 8, 15, 18)
        )
        let nineOClock = snapshot.buckets.first {
            calendar.component(.hour, from: $0.interval.start) == 9
        }

        #expect(nineOClock?.focusTime == 1_800)
        #expect(nineOClock?.completedSessions == 1)
    }

    @Test("Period and bucket ends are exclusive")
    func excludesExactEndBoundaries() {
        let midnightSession = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 16),
            activeDuration: 1_500
        )
        let midnightTask = FocusTask(
            title: "Tomorrow",
            completedAt: date(2026, 8, 16)
        )

        let snapshot = calculator.snapshot(
            sessions: [midnightSession],
            tasks: [midnightTask],
            period: .day,
            now: date(2026, 8, 15, 18)
        )

        #expect(snapshot.current.focusTime == 0)
        #expect(snapshot.current.completedSessions == 0)
        #expect(snapshot.current.completedTasks == 0)
        #expect(snapshot.buckets.allSatisfy { $0.focusTime == 0 })
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }

    private var calculator: StatsCalculator {
        StatsCalculator(calendar: calendar)
    }

    private func focusSession(
        state: SessionState,
        startedAt: Date,
        activeDuration: TimeInterval,
        category: FocusCategory? = nil
    ) -> FocusSession {
        FocusSession(
            kind: .focus,
            state: state,
            startedAt: startedAt,
            plannedDuration: 1_500,
            actualActiveDuration: activeDuration,
            category: category,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }
}
