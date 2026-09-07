import Foundation
import SwiftData

enum TaskPriority: Int, Codable, CaseIterable, Sendable {
    case low
    case normal
    case high
}

@Model
final class FocusTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    private var priorityRawValue: Int
    var estimatedPomodoros: Int
    var sortOrder: Int
    var isArchived: Bool
    var category: FocusCategory?
    @Relationship(deleteRule: .nullify) var timerRoutine: TimerRoutine?

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.task)
    var sessions: [FocusSession]

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .normal }
        set { priorityRawValue = newValue.rawValue }
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var completedPomodoros: Int {
        sessions.count {
            $0.kind == .focus && $0.state == .completed
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        category: FocusCategory? = nil,
        timerRoutine: TimerRoutine? = nil,
        priority: TaskPriority = .normal,
        estimatedPomodoros: Int = 1,
        sortOrder: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.category = category
        self.timerRoutine = timerRoutine
        self.priorityRawValue = priority.rawValue
        self.estimatedPomodoros = max(1, estimatedPomodoros)
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.sessions = []
    }

    func complete(at date: Date = .now) {
        completedAt = date
    }

    func reopen() {
        completedAt = nil
    }
}
