import Foundation

struct StatsCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func snapshot(
        sessions: [FocusSession],
        tasks: [FocusTask],
        period: StatsPeriod,
        now: Date = .now
    ) -> StatsSnapshot {
        let currentInterval = period.interval(containing: now, calendar: calendar)
        let previousInterval = period.previousInterval(containing: now, calendar: calendar)
        let currentSessions = focusSessions(sessions, in: currentInterval)
        let previousSessions = focusSessions(sessions, in: previousInterval)
        let current = metrics(
            sessions: currentSessions,
            tasks: tasks,
            interval: currentInterval
        )
        let previous = metrics(
            sessions: previousSessions,
            tasks: tasks,
            interval: previousInterval
        )

        return StatsSnapshot(
            period: period,
            currentInterval: currentInterval,
            previousInterval: previousInterval,
            current: current,
            previous: previous,
            focusTimeComparison: comparison(
                current: current.focusTime,
                previous: previous.focusTime
            ),
            completedSessionsComparison: comparison(
                current: Double(current.completedSessions),
                previous: Double(previous.completedSessions)
            ),
            completedTasksComparison: comparison(
                current: Double(current.completedTasks),
                previous: Double(previous.completedTasks)
            ),
            buckets: buckets(
                for: currentSessions,
                period: period,
                now: now
            ),
            categories: categories(for: currentSessions)
        )
    }

    private func focusSessions(
        _ sessions: [FocusSession],
        in interval: DateInterval
    ) -> [FocusSession] {
        sessions.filter {
            $0.kind == .focus && contains($0.startedAt, in: interval)
        }
    }

    private func metrics(
        sessions: [FocusSession],
        tasks: [FocusTask],
        interval: DateInterval
    ) -> StatsMetrics {
        StatsMetrics(
            focusTime: sessions.reduce(0) { result, session in
                result + session.actualActiveDuration
            },
            completedSessions: sessions.count { $0.state == .completed },
            completedTasks: tasks.count { task in
                guard let completedAt = task.completedAt else { return false }
                return contains(completedAt, in: interval)
            }
        )
    }

    private func comparison(current: Double, previous: Double) -> StatsComparison {
        guard previous > 0 else {
            return current > 0 ? .new : .unavailable
        }

        let percent = ((current - previous) / previous) * 100
        return abs(percent) < 0.000_001
            ? .unchanged
            : .change(percent: percent)
    }

    private func buckets(
        for sessions: [FocusSession],
        period: StatsPeriod,
        now: Date
    ) -> [StatsBucket] {
        period.bucketIntervals(containing: now, calendar: calendar).map { interval in
            let matchingSessions = sessions.filter {
                contains($0.startedAt, in: interval)
            }
            return StatsBucket(
                interval: interval,
                focusTime: matchingSessions.reduce(0) { result, session in
                    result + session.actualActiveDuration
                },
                completedSessions: matchingSessions.count { $0.state == .completed }
            )
        }
    }

    private func categories(for sessions: [FocusSession]) -> [CategoryFocusStat] {
        struct CategoryKey: Hashable {
            let name: String
            let colorToken: String
        }

        var focusByCategory: [CategoryKey: TimeInterval] = [:]

        for session in sessions where session.actualActiveDuration > 0 {
            let key = CategoryKey(
                name: session.categoryNameSnapshot
                    ?? session.category?.name
                    ?? "Uncategorized",
                colorToken: session.categoryColorTokenSnapshot
                    ?? session.category?.colorToken
                    ?? "secondary"
            )
            focusByCategory[key, default: 0] += session.actualActiveDuration
        }

        let total = focusByCategory.values.reduce(0, +)
        guard total > 0 else { return [] }

        return focusByCategory
            .map { key, focusTime in
                CategoryFocusStat(
                    name: key.name,
                    colorToken: key.colorToken,
                    focusTime: focusTime,
                    fraction: focusTime / total
                )
            }
            .sorted {
                if $0.focusTime == $1.focusTime {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.focusTime > $1.focusTime
            }
    }

    private func contains(_ date: Date, in interval: DateInterval) -> Bool {
        date >= interval.start && date < interval.end
    }
}
