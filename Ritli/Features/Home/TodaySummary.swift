import Foundation

struct TodaySummary: Equatable {
    let completedSessions: Int
    let focusTime: TimeInterval
    let completedTasks: Int

    init(
        sessions: [FocusSession],
        tasks: [FocusTask],
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        let todaysFocusSessions = sessions.filter {
            $0.kind == .focus && calendar.isDate($0.startedAt, inSameDayAs: now)
        }

        self.completedSessions = todaysFocusSessions.count {
            $0.state == .completed
        }
        self.focusTime = todaysFocusSessions.reduce(0) {
            $0 + $1.actualActiveDuration
        }
        self.completedTasks = tasks.count { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: now)
        }
    }
}
