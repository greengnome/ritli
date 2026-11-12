import Foundation
import Testing
@testable import Ritli

struct StatsPeriodTests {
    @Test("Periods resolve current and immediately preceding calendar ranges")
    func resolvesPeriodRanges() {
        let calendar = testCalendar
        let now = date(2026, 8, 15, 12)

        let day = StatsPeriod.day.interval(containing: now, calendar: calendar)
        let previousDay = StatsPeriod.day.previousInterval(
            containing: now,
            calendar: calendar
        )

        #expect(day.start == date(2026, 8, 15))
        #expect(day.end == date(2026, 8, 16))
        #expect(previousDay.start == date(2026, 8, 14))
        #expect(previousDay.end == day.start)
    }

    @Test("Bucket counts follow the selected calendar period")
    func createsPeriodBuckets() {
        let calendar = testCalendar
        let now = date(2026, 8, 15, 12)

        #expect(StatsPeriod.day.bucketIntervals(containing: now, calendar: calendar).count == 24)
        #expect(StatsPeriod.week.bucketIntervals(containing: now, calendar: calendar).count == 7)
        #expect(StatsPeriod.month.bucketIntervals(containing: now, calendar: calendar).count == 31)
        #expect(StatsPeriod.year.bucketIntervals(containing: now, calendar: calendar).count == 12)
    }

    @Test("Period copy resolves in English and Ukrainian", arguments: [
        (StatsPeriod.day, "Day", "День", "Tasks completed today", "Завдання, виконані сьогодні"),
        (StatsPeriod.week, "Week", "Тиждень", "Tasks completed this week", "Завдання, виконані цього тижня"),
        (StatsPeriod.month, "Month", "Місяць", "Tasks completed this month", "Завдання, виконані цього місяця"),
        (StatsPeriod.year, "Year", "Рік", "Tasks completed this year", "Завдання, виконані цього року"),
    ])
    func localizesPeriodCopy(
        period: StatsPeriod,
        englishTitle: String,
        ukrainianTitle: String,
        englishDescription: String,
        ukrainianDescription: String
    ) throws {
        let englishBundle = try TestLocalization.bundle(language: "en")
        let ukrainianBundle = try TestLocalization.bundle(language: "uk")

        #expect(period.title(bundle: englishBundle, locale: Locale(identifier: "en")) == englishTitle)
        #expect(period.title(bundle: ukrainianBundle, locale: Locale(identifier: "uk")) == ukrainianTitle)
        #expect(period.completedTasksDescription(bundle: englishBundle, locale: Locale(identifier: "en")) == englishDescription)
        #expect(period.completedTasksDescription(bundle: ukrainianBundle, locale: Locale(identifier: "uk")) == ukrainianDescription)
    }

    @Test("Daylight-saving days have 23 or 25 hourly buckets", arguments: [
        (3, 8, 23),
        (11, 1, 25),
    ])
    func dstDayBuckets(month: Int, day: Int, expected: Int) {
        let losAngeles = TestCalendar.zoned("America/Los_Angeles")
        let now = TestCalendar.date(2026, month, day, 12, in: losAngeles)

        #expect(StatsPeriod.day.bucketIntervals(containing: now, calendar: losAngeles).count == expected)
    }

    @Test("Weeks follow the calendar's first weekday", arguments: [
        (1, 16), // Sunday-first (en_US): the week of Sat 22 Aug starts Sun 16 Aug
        (2, 17), // Monday-first: it starts Mon 17 Aug
    ])
    func weekStartFollowsFirstWeekday(firstWeekday: Int, expectedStartDay: Int) {
        let calendar = TestCalendar.utc(firstWeekday: firstWeekday)
        let saturday = TestCalendar.date(2026, 8, 22, 12, in: calendar)

        let week = StatsPeriod.week.interval(containing: saturday, calendar: calendar)

        #expect(week.start == TestCalendar.date(2026, 8, expectedStartDay, in: calendar))
        #expect(week.duration == 7 * 86_400)
    }

    @Test("The comparable part of last month is clamped to its end", arguments: [
        (31, 2, 28), // 31 March → up to 28 Feb 12:00
        (15, 2, 15), // 15 March → up to 15 Feb 12:00
    ])
    func previousElapsedMonth(day: Int, expectedMonth: Int, expectedDay: Int) {
        let now = date(2026, 3, day, 12)

        let previous = StatsPeriod.month.previousElapsedInterval(containing: now, calendar: testCalendar)

        #expect(previous.start == date(2026, 2, 1))
        #expect(previous.end == date(2026, expectedMonth, expectedDay, 12))
    }

    private let testCalendar = TestCalendar.utc()

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0
    ) -> Date {
        TestCalendar.date(year, month, day, hour, in: testCalendar)
    }
}
