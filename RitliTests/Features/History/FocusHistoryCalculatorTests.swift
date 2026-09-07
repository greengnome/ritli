import Foundation
import Testing
@testable import Ritli

@MainActor
struct FocusHistoryCalculatorTests {
    @Test("A day summarizes terminal focus sessions and completed tasks")
    func summarizesDay() {
        let completed = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 15, 10),
            activeDuration: 1_500
        )
        let cancelled = focusSession(
            state: .cancelled,
            startedAt: date(2026, 8, 15, 9),
            activeDuration: 600
        )
        let running = focusSession(
            state: .running,
            startedAt: date(2026, 8, 15, 11),
            activeDuration: 300
        )
        let breakSession = FocusSession(
            kind: .shortBreak,
            state: .completed,
            startedAt: date(2026, 8, 15, 12),
            plannedDuration: 300,
            actualActiveDuration: 300
        )
        let todayTask = FocusTask(
            title: "Done today",
            completedAt: date(2026, 8, 15, 13)
        )
        let tomorrowTask = FocusTask(
            title: "Done tomorrow",
            completedAt: date(2026, 8, 16)
        )

        let day = calculator.day(
            containing: date(2026, 8, 15, 18),
            sessions: [completed, running, breakSession, cancelled],
            tasks: [todayTask, tomorrowTask]
        )

        #expect(day.focusTime == 2_100)
        #expect(day.completedSessions == 1)
        #expect(day.completedTasks == 1)
        #expect(day.entries.map(\.state) == [.cancelled, .completed])
        #expect(day.entries.map(\.startedAt) == [
            date(2026, 8, 15, 9),
            date(2026, 8, 15, 10)
        ])
    }

    @Test("Entries preserve historical category snapshots and task context")
    func preservesHistoricalContext() {
        let category = FocusCategory(name: "Work", colorToken: "coral")
        let task = FocusTask(title: "Project roadmap", category: category)
        let assigned = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: date(2026, 8, 15, 9),
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task,
            category: category,
            timeZone: calendar.timeZone
        )
        let unassigned = focusSession(
            state: .cancelled,
            startedAt: date(2026, 8, 15, 10),
            activeDuration: 300
        )
        category.name = "Renamed"
        category.colorToken = "blue"

        let day = calculator.day(
            containing: date(2026, 8, 15),
            sessions: [assigned, unassigned],
            tasks: []
        )

        #expect(day.entries[0].taskTitle == "Project roadmap")
        #expect(day.entries[0].categoryName == "Work")
        #expect(day.entries[0].categoryColorToken == "coral")
        #expect(day.entries[1].taskTitle == nil)
        #expect(day.entries[1].categoryName == nil)
    }

    @Test("The exact end of a day belongs only to the next day")
    func excludesEndBoundary() {
        let midnight = focusSession(
            state: .completed,
            startedAt: date(2026, 8, 16),
            activeDuration: 1_500
        )
        let task = FocusTask(
            title: "Tomorrow",
            completedAt: date(2026, 8, 16)
        )

        let day = calculator.day(
            containing: date(2026, 8, 15, 12),
            sessions: [midnight],
            tasks: [task]
        )

        #expect(day.isEmpty)
        #expect(day.focusTime == 0)
        #expect(day.completedSessions == 0)
        #expect(day.completedTasks == 0)
    }

    @Test("Calendar days respect daylight-saving transitions")
    func respectsDaylightSavingTime() {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let calculator = FocusHistoryCalculator(calendar: losAngeles)
        let springForwardDay = losAngeles.date(
            from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)
        )!
        let sessionDate = losAngeles.date(
            from: DateComponents(year: 2026, month: 3, day: 8, hour: 3)
        )!
        let session = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: sessionDate,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            timeZone: losAngeles.timeZone
        )

        let day = calculator.day(
            containing: springForwardDay,
            sessions: [session],
            tasks: []
        )

        #expect(day.interval.duration == 23 * 60 * 60)
        #expect(day.entries.map(\.id) == [session.id])
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }

    private var calculator: FocusHistoryCalculator {
        FocusHistoryCalculator(calendar: calendar)
    }

    private func focusSession(
        state: SessionState,
        startedAt: Date,
        activeDuration: TimeInterval
    ) -> FocusSession {
        FocusSession(
            kind: .focus,
            state: state,
            startedAt: startedAt,
            plannedDuration: 1_500,
            actualActiveDuration: activeDuration,
            timeZone: calendar.timeZone
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}
