import Foundation
import Testing
@testable import Ritli

struct TimerDisplayFormatterTests {
    @Test("The remaining ring starts full, counts down, and clamps terminal values", arguments: [
        (TimeInterval(1_500), TimeInterval(1_500), 1.0),
        (TimeInterval(750), TimeInterval(1_500), 0.5),
        (TimeInterval(0), TimeInterval(1_500), 0.0),
        (TimeInterval(-1), TimeInterval(1_500), 0.0),
        (TimeInterval(2_000), TimeInterval(1_500), 1.0),
        (TimeInterval(1), TimeInterval(0), 0.0),
    ])
    func remainingRing(remaining: TimeInterval, duration: TimeInterval, expected: Double) {
        #expect(TimerDisplayFormatter.remainingFraction(remaining, duration: duration) == expected)
    }

    @Test("The planned-session label resolves in both languages", arguments: [
        ("en", "25 min session"),
        ("uk", "Сесія 25 хв"),
    ])
    func sessionDurationLabel(language: String, expected: String) throws {
        let bundle = try localizedBundle(language: language)
        #expect(TimerDisplayFormatter.sessionDurationLabel(
            1_500, bundle: bundle, locale: Locale(identifier: language)
        ) == expected)
    }

    @Test("Countdown rounds up partial seconds", arguments: [
        (TimeInterval(1_500), "25:00"),
        (TimeInterval(1_499.1), "25:00"),
        (TimeInterval(59), "00:59"),
        (TimeInterval(-1), "00:00"),
    ])
    func countdown(interval: TimeInterval, expected: String) {
        #expect(TimerDisplayFormatter.countdown(interval) == expected)
    }

    @Test("Focused time uses compact hour and minute units", arguments: [
        (TimeInterval(0), "0m"),
        (TimeInterval(45 * 60), "45m"),
        (TimeInterval(2 * 60 * 60), "2h"),
        (TimeInterval(2 * 60 * 60 + 15 * 60), "2h 15m"),
    ])
    func focusedTime(interval: TimeInterval, expected: String) {
        #expect(TimerDisplayFormatter.focusedTime(interval) == expected)
    }

    @Test("Compact time resolves in Ukrainian", arguments: [
        (TimeInterval(0), "0 хв"),
        (TimeInterval(45 * 60), "45 хв"),
        (TimeInterval(2 * 60 * 60), "2 год"),
        (TimeInterval(2 * 60 * 60 + 15 * 60), "2 год 15 хв"),
    ])
    func focusedTimeInUkrainian(
        interval: TimeInterval,
        expected: String
    ) throws {
        let bundle = try localizedBundle(language: "uk")

        #expect(
            TimerDisplayFormatter.focusedTime(
                interval,
                bundle: bundle,
                locale: Locale(identifier: "uk")
            ) == expected
        )
    }

    @Test("Timer duration resolves in each supported language", arguments: [
        ("en", "25 min"),
        ("uk", "25 хв"),
    ])
    func durationLabel(language: String, expected: String) throws {
        let bundle = try localizedBundle(language: language)

        #expect(
            TimerDisplayFormatter.durationLabel(
                25 * 60,
                bundle: bundle,
                locale: Locale(identifier: language)
            ) == expected
        )
    }

    @Test("Session count follows English and Ukrainian plural rules", arguments: [
        ("en", 1, "1 session"),
        ("en", 2, "2 sessions"),
        ("uk", 1, "1 сесія"),
        ("uk", 2, "2 сесії"),
        ("uk", 5, "5 сесій"),
        ("uk", 21, "21 сесія"),
    ])
    func sessionCount(
        language: String,
        count: Int,
        expected: String
    ) throws {
        let bundle = try localizedBundle(language: language)

        #expect(
            TimerDisplayFormatter.sessionCount(
                count,
                bundle: bundle,
                locale: Locale(identifier: language)
            ) == expected
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
