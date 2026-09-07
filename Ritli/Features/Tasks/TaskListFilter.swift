import Foundation

enum TaskListFilter: Hashable {
    case all
    case category(UUID)

    func includes(_ task: FocusTask) -> Bool {
        switch self {
        case .all:
            true
        case .category(let categoryID):
            task.category?.id == categoryID
        }
    }
}

enum TaskListPresentation {
    static func visibleTasks(
        from tasks: [FocusTask],
        filter: TaskListFilter
    ) -> [FocusTask] {
        tasks
            .filter { !$0.isArchived && filter.includes($0) }
            .sorted(by: comesBefore)
    }

    static func archivedTasks(from tasks: [FocusTask]) -> [FocusTask] {
        tasks
            .filter(\.isArchived)
            .sorted(by: comesBefore)
    }

    nonisolated private static func comesBefore(
        _ lhs: FocusTask,
        _ rhs: FocusTask
    ) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
