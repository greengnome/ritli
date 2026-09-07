import Foundation

struct StatsMetrics: Equatable, Sendable {
    let focusTime: TimeInterval
    let completedSessions: Int
    let completedTasks: Int
}

enum StatsComparison: Equatable, Sendable {
    case unavailable
    case new
    case unchanged
    case change(percent: Double)
}

struct StatsBucket: Equatable, Identifiable, Sendable {
    let interval: DateInterval
    let focusTime: TimeInterval
    let completedSessions: Int

    var id: Date { interval.start }
}

struct CategoryFocusStat: Equatable, Identifiable, Sendable {
    let name: String
    let colorToken: String
    let focusTime: TimeInterval
    let fraction: Double

    var id: String { "\(name)|\(colorToken)" }
}

struct StatsSnapshot: Equatable, Sendable {
    let period: StatsPeriod
    let currentInterval: DateInterval
    let previousInterval: DateInterval
    let current: StatsMetrics
    let previous: StatsMetrics
    let focusTimeComparison: StatsComparison
    let completedSessionsComparison: StatsComparison
    let completedTasksComparison: StatsComparison
    let buckets: [StatsBucket]
    let categories: [CategoryFocusStat]
}
