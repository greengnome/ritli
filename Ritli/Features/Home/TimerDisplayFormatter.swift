import Foundation

enum TimerDisplayFormatter {
    static func countdown(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(ceil(max(0, interval)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func durationLabel(
        _ interval: TimeInterval,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        let minutes = Int(interval / 60)
        return String(
            localized: "time.duration.minutes",
            defaultValue: "\(minutes) min",
            bundle: bundle,
            locale: locale
        )
    }

    static func focusedTime(
        _ interval: TimeInterval,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return String(
                localized: "time.compact.minutes",
                defaultValue: "\(minutes)m",
                bundle: bundle,
                locale: locale
            )
        }
        if minutes == 0 {
            return String(
                localized: "time.compact.hours",
                defaultValue: "\(hours)h",
                bundle: bundle,
                locale: locale
            )
        }
        return String(
            localized: "time.compact.hours_minutes",
            defaultValue: "\(hours)h \(minutes)m",
            bundle: bundle,
            locale: locale
        )
    }

    static func sessionCount(
        _ count: Int,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        String(
            localized: "common.session_count",
            defaultValue: "\(count) sessions",
            bundle: bundle,
            locale: locale
        )
    }
}
