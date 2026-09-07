import Foundation
import Testing
@testable import Ritli

@MainActor
struct StatsComparisonPresentationTests {
    @Test("Comparison copy uses the selected period")
    func usesPeriodComparisonLabels() {
        let presentation = StatsComparisonPresentation.make(
            comparison: .change(percent: 18.4),
            period: .week
        )

        #expect(presentation.text == "18% vs last week")
        #expect(presentation.systemImage == "arrow.up.circle.fill")
        #expect(presentation.tone == .positive)
    }

    @Test("Negative comparisons use absolute copy and a negative tone")
    func presentsNegativeChanges() {
        let presentation = StatsComparisonPresentation.make(
            comparison: .change(percent: -12.8),
            period: .month
        )

        #expect(presentation.text == "13% vs last month")
        #expect(presentation.systemImage == "arrow.down.circle.fill")
        #expect(presentation.tone == .negative)
    }

    @Test("Zero-baseline states never display an infinite percentage")
    func presentsZeroBaselineStates() {
        let newValue = StatsComparisonPresentation.make(
            comparison: .new,
            period: .day
        )
        let unavailable = StatsComparisonPresentation.make(
            comparison: .unavailable,
            period: .year
        )

        #expect(newValue.text == "New vs yesterday")
        #expect(newValue.tone == .positive)
        #expect(unavailable.text == "No previous data")
        #expect(unavailable.tone == .neutral)
    }

    @Test("Comparison copy resolves in Ukrainian")
    func localizesComparisons() throws {
        let bundle = try localizedBundle(language: "uk")
        let locale = Locale(identifier: "uk")

        let positive = StatsComparisonPresentation.make(
            comparison: .change(percent: 18.4),
            period: .week,
            bundle: bundle,
            locale: locale
        )
        let newValue = StatsComparisonPresentation.make(
            comparison: .new,
            period: .day,
            bundle: bundle,
            locale: locale
        )

        #expect(positive.text == "18% — порівняно з минулим тижнем")
        #expect(newValue.text == "Новий результат — порівняно з учора")
    }

    @Test("Bucket labels match chart granularity")
    func formatsBucketLabels() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let date = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 15, hour: 9)
        )!

        let hourLabel = StatsPeriod.day
            .bucketLabel(for: date, calendar: calendar)
            .replacingOccurrences(of: "\u{202F}", with: " ")

        #expect(hourLabel == "9 AM")
        #expect(StatsPeriod.week.bucketLabel(for: date, calendar: calendar) == "Sat")
        #expect(StatsPeriod.month.bucketLabel(for: date, calendar: calendar) == "15")
        #expect(StatsPeriod.year.bucketLabel(for: date, calendar: calendar) == "Aug")
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
