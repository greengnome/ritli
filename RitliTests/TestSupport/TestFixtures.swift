import Foundation
import Testing

/// Loads a specific `.lproj` so assertions don't depend on the simulator language.
enum TestLocalization {
    static func bundle(language: String, in host: Bundle = .main) throws -> Bundle {
        let path = try #require(host.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }
}

/// A fixed Gregorian calendar so date math doesn't depend on the host's
/// time zone, locale or first weekday.
enum TestCalendar {
    static func utc(firstWeekday: Int = 2) -> Calendar {
        zoned("UTC", firstWeekday: firstWeekday)
    }

    static func zoned(_ identifier: String, firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        in calendar: Calendar = utc()
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

/// Polls `condition` until it holds or `timeout` passes, instead of sleeping
/// for a fixed time and hoping the system was fast enough.
@MainActor
func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @MainActor () -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while !condition() {
        guard clock.now < deadline else { return false }
        try? await Task.sleep(for: .milliseconds(20))
    }
    return true
}
