import Foundation

struct FocusHistoryEntry: Equatable, Identifiable, Sendable {
    let id: UUID
    let startedAt: Date
    let focusTime: TimeInterval
    let state: SessionState
    let taskTitle: String?
    let categoryName: String?
    let categoryColorToken: String?

    var isCompleted: Bool {
        state == .completed
    }
}
