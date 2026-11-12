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

    @Test("The comparison uses the same elapsed part of the previous period")
    func comparesWithElapsedPartOfPreviousPeriod() {
        // Monday 9:00 vs last week up to Monday 9:00, not all of last week.
        let now = date(2026, 8, 17, 9)
        let lastMondayMorning = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 10, 8),
            activeDuration: 1_500
        )
        let lastWednesday = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 12, 10),
            activeDuration: 1_500
        )
        let thisMonday = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 17, 8),
            activeDuration: 1_500
        )

        let snapshot = calculator.snapshot(
            sessions: [lastMondayMorning, lastWednesday, thisMonday],
            tasks: [FocusTask(title: "Later", completedAt: date(2026, 8, 11, 9))],
            period: .week,
            now: now
        )

        #expect(snapshot.previous.completedSessions == 1)
        #expect(snapshot.previous.completedTasks == 0)
        #expect(snapshot.completedSessionsComparison == .unchanged)
        #expect(snapshot.previousInterval.duration == 7 * 86_400)
    }

    @Test("Running and paused sessions are left out until they finish")
    func excludesUnfinishedSessions() {
        let running = focusSession(
            state: .running,
            startedAt: date(2026, 8, 15, 9),
            activeDuration: 0
        )
        let paused = focusSession(
            state: .paused,
            startedAt: date(2026, 8, 15, 10),
            activeDuration: 720
        )

        let snapshot = calculator.snapshot(
            sessions: [running, paused],
            tasks: [],
            period: .day,
            now: date(2026, 8, 15, 18)
        )

        #expect(snapshot.current.focusTime == 0)
        #expect(snapshot.categories.isEmpty)
    }

    @Test("A change that rounds to 0% is reported as unchanged")
    func treatsRoundedZeroAsUnchanged() {
        let today = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 15, 9),
            activeDuration: 996
        )
        let yesterday = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 14, 9),
            activeDuration: 1_000
        )

        let snapshot = calculator.snapshot(
            sessions: [today, yesterday],
            tasks: [],
            period: .day,
            now: date(2026, 8, 15, 18)
        )

        #expect(snapshot.focusTimeComparison == .unchanged)
    }

    private let calendar = TestCalendar.utc()

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
        TestCalendar.date(year, month, day, hour, minute, in: calendar)
    }
}
