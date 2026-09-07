import Foundation

enum StatsComparisonTone: Equatable, Sendable {
    case positive
    case negative
    case neutral
}

struct StatsComparisonPresentation: Equatable, Sendable {
    let text: String
    let systemImage: String
    let tone: StatsComparisonTone

    static func make(
        comparison: StatsComparison,
        period: StatsPeriod,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> StatsComparisonPresentation {
        let comparisonLabel = period.comparisonLabel(
            bundle: bundle,
            locale: locale
        )

        switch comparison {
        case .unavailable:
            return StatsComparisonPresentation(
                text: String(
                    localized: "stats.comparison.no_previous_data",
                    defaultValue: "No previous data",
                    bundle: bundle,
                    locale: locale
                ),
                systemImage: "minus.circle.fill",
                tone: .neutral
            )
        case .new:
            return StatsComparisonPresentation(
                text: String(
                    localized: "stats.comparison.new",
                    defaultValue: "New vs \(comparisonLabel)",
                    bundle: bundle,
                    locale: locale
                ),
                systemImage: "sparkles",
                tone: .positive
            )
        case .unchanged:
            return StatsComparisonPresentation(
                text: String(
                    localized: "stats.comparison.unchanged",
                    defaultValue: "No change vs \(comparisonLabel)",
                    bundle: bundle,
                    locale: locale
                ),
                systemImage: "equal.circle.fill",
                tone: .neutral
            )
        case .change(let percent):
            let roundedPercent = Int(percent.rounded())
            return StatsComparisonPresentation(
                text: String(
                    localized: "stats.comparison.change",
                    defaultValue: "\(abs(roundedPercent))% vs \(comparisonLabel)",
                    bundle: bundle,
                    locale: locale
                ),
                systemImage: roundedPercent >= 0
                    ? "arrow.up.circle.fill"
                    : "arrow.down.circle.fill",
                tone: roundedPercent >= 0 ? .positive : .negative
            )
        }
    }
}

extension StatsPeriod {
    func bucketLabel(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.timeZone = calendar.timeZone

        switch self {
        case .day:
            formatter.setLocalizedDateFormatFromTemplate("j")
        case .week:
            formatter.setLocalizedDateFormatFromTemplate("EEE")
        case .month:
            formatter.setLocalizedDateFormatFromTemplate("d")
        case .year:
            formatter.setLocalizedDateFormatFromTemplate("MMM")
        }

        return formatter.string(from: date)
    }
}
