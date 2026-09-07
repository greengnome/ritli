import Foundation

struct FocusHistoryCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func day(
        containing date: Date,
        sessions: [FocusSession],
        tasks: [FocusTask]
    ) -> FocusHistoryDay {
        let interval = calendar.dateInterval(of: .day, for: date)
            ?? DateInterval(
                start: calendar.startOfDay(for: date),
                duration: 86_400
            )
        let historicalSessions = sessions
            .filter { session in
                session.kind == .focus
                    && session.state.isTerminal
                    && contains(session.startedAt, in: interval)
            }
            .sorted { lhs, rhs in
                if lhs.startedAt == rhs.startedAt {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.startedAt < rhs.startedAt
            }
        let entries = historicalSessions.map(entry(for:))

        return FocusHistoryDay(
            interval: interval,
            focusTime: entries.reduce(0) { $0 + $1.focusTime },
            completedSessions: entries.count(where: \.isCompleted),
            completedTasks: tasks.count { task in
                guard let completedAt = task.completedAt else { return false }
                return contains(completedAt, in: interval)
            },
            entries: entries
        )
    }

    private func entry(for session: FocusSession) -> FocusHistoryEntry {
        FocusHistoryEntry(
            id: session.id,
            startedAt: session.startedAt,
            focusTime: session.actualActiveDuration,
            state: session.state,
            taskTitle: session.task?.title,
            categoryName: session.categoryNameSnapshot ?? session.category?.name,
            categoryColorToken: session.categoryColorTokenSnapshot
                ?? session.category?.colorToken
        )
    }

    private func contains(_ date: Date, in interval: DateInterval) -> Bool {
        date >= interval.start && date < interval.end
    }
}
