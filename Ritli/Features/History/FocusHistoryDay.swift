import Foundation

struct FocusHistoryDay: Equatable, Sendable {
    let interval: DateInterval
    let focusTime: TimeInterval
    let completedSessions: Int
    let completedTasks: Int
    let entries: [FocusHistoryEntry]
}
