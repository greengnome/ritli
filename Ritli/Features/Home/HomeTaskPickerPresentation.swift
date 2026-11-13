import Foundation

enum HomeTaskPickerPresentation {
    static func selectableTasks(from tasks: [FocusTask]) -> [FocusTask] {
        tasks
            .filter { !$0.isArchived && !$0.isCompleted }
            .sorted(by: TaskListPresentation.comesBefore)
    }
}
