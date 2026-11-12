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

    @Test("Entries keep the task title after the task is deleted")
    func keepsTitleOfDeletedTask() {
        let task = FocusTask(title: "Old project")
        let session = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: date(2026, 8, 15, 9),
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task,
            timeZone: calendar.timeZone
        )
        session.task = nil

        let day = calculator.day(containing: date(2026, 8, 15), sessions: [session], tasks: [])

        #expect(day.entries.first?.taskTitle == "Old project")
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

        #expect(day.entries.isEmpty)
        #expect(day.focusTime == 0)
        #expect(day.completedSessions == 0)
        #expect(day.completedTasks == 0)
    }

    @Test("Calendar days respect daylight-saving transitions", arguments: [
        (3, 8, 23.0),  // spring forward
        (11, 1, 25.0), // fall back
    ])
    func respectsDaylightSavingTime(month: Int, day transitionDay: Int, hours: Double) {
        let losAngeles = TestCalendar.zoned("America/Los_Angeles")
        let calculator = FocusHistoryCalculator(calendar: losAngeles)
        let transitionNoon = TestCalendar.date(2026, month, transitionDay, 12, in: losAngeles)
        let sessionDate = TestCalendar.date(2026, month, transitionDay, 3, in: losAngeles)
        let session = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: sessionDate,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            timeZone: losAngeles.timeZone
        )

        let day = calculator.day(
            containing: transitionNoon,
            sessions: [session],
            tasks: []
        )

        #expect(day.interval.duration == hours * 60 * 60)
        #expect(day.entries.map(\.id) == [session.id])
    }

    private let calendar = TestCalendar.utc()

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
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        TestCalendar.date(year, month, day, hour, minute, in: calendar)
    }
}
