import Foundation

enum HomeTaskPickerPresentation {
    static func selectableTasks(from tasks: [FocusTask]) -> [FocusTask] {
        tasks
            .filter { !$0.isArchived && !$0.isCompleted }
            .sorted(by: comesBefore)
    }

    nonisolated private static func comesBefore(
        _ lhs: FocusTask,
        _ rhs: FocusTask
    ) -> Bool {
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
