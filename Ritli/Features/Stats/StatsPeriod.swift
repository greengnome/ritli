import Foundation

enum StatsPeriod: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    func title(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch self {
        case .day:
            String(
                localized: "stats.period.day",
                defaultValue: "Day",
                bundle: bundle,
                locale: locale
            )
        case .week:
            String(
                localized: "stats.period.week",
                defaultValue: "Week",
                bundle: bundle,
                locale: locale
            )
        case .month:
            String(
                localized: "stats.period.month",
                defaultValue: "Month",
                bundle: bundle,
                locale: locale
            )
        case .year:
            String(
                localized: "stats.period.year",
                defaultValue: "Year",
                bundle: bundle,
                locale: locale
            )
        }
    }

    func comparisonLabel(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch self {
        case .day:
            String(
                localized: "stats.comparison.period.day",
                defaultValue: "yesterday",
                bundle: bundle,
                locale: locale
            )
        case .week:
            String(
                localized: "stats.comparison.period.week",
                defaultValue: "last week",
                bundle: bundle,
                locale: locale
            )
        case .month:
            String(
                localized: "stats.comparison.period.month",
                defaultValue: "last month",
                bundle: bundle,
                locale: locale
            )
        case .year:
            String(
                localized: "stats.comparison.period.year",
                defaultValue: "last year",
                bundle: bundle,
                locale: locale
            )
        }
    }

    func completedTasksDescription(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch self {
        case .day:
            String(
                localized: "stats.tasks.description.day",
                defaultValue: "Tasks completed today",
                bundle: bundle,
                locale: locale
            )
        case .week:
            String(
                localized: "stats.tasks.description.week",
                defaultValue: "Tasks completed this week",
                bundle: bundle,
                locale: locale
            )
        case .month:
            String(
                localized: "stats.tasks.description.month",
                defaultValue: "Tasks completed this month",
                bundle: bundle,
                locale: locale
            )
        case .year:
            String(
                localized: "stats.tasks.description.year",
                defaultValue: "Tasks completed this year",
                bundle: bundle,
                locale: locale
            )
        }
    }

    func interval(containing date: Date, calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: periodComponent, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 86_400)
    }

    func previousInterval(containing date: Date, calendar: Calendar) -> DateInterval {
        let current = interval(containing: date, calendar: calendar)
        let previousAnchor = calendar.date(
            byAdding: periodComponent,
            value: -1,
            to: current.start
        ) ?? current.start.addingTimeInterval(-current.duration)

        return interval(containing: previousAnchor, calendar: calendar)
    }

    func bucketIntervals(containing date: Date, calendar: Calendar) -> [DateInterval] {
        let periodInterval = interval(containing: date, calendar: calendar)
        var buckets: [DateInterval] = []
        var cursor = periodInterval.start

        while cursor < periodInterval.end {
            guard let candidateEnd = calendar.date(
                byAdding: bucketComponent,
                value: 1,
                to: cursor
            ) else {
                break
            }

            let end = min(candidateEnd, periodInterval.end)
            guard end > cursor else { break }
            buckets.append(DateInterval(start: cursor, end: end))
            cursor = end
        }

        return buckets
    }

    private var periodComponent: Calendar.Component {
        switch self {
        case .day:
            .day
        case .week:
            .weekOfYear
        case .month:
            .month
        case .year:
            .year
        }
    }

    private var bucketComponent: Calendar.Component {
        switch self {
        case .day:
            .hour
        case .week, .month:
            .day
        case .year:
            .month
        }
    }

}
