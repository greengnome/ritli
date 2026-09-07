import Foundation
import Testing
@testable import Ritli

struct TaskListFilterTests {
    @Test("Category filters include only matching active tasks")
    func filtersByCategory() {
        let work = FocusCategory(name: "Work", colorToken: "coral")
        let personal = FocusCategory(name: "Personal", colorToken: "green")
        let workTask = FocusTask(title: "Roadmap", category: work)
        let personalTask = FocusTask(title: "Workout", category: personal)
        let archivedTask = FocusTask(
            title: "Old roadmap",
            category: work,
            isArchived: true
        )

        let result = TaskListPresentation.visibleTasks(
            from: [workTask, personalTask, archivedTask],
            filter: .category(work.id)
        )

        #expect(result.map(\.title) == ["Roadmap"])
    }

    @Test("Active tasks sort before completed tasks and preserve explicit order")
    func sortsVisibleTasks() {
        let first = FocusTask(
            title: "First",
            createdAt: Date(timeIntervalSince1970: 20),
            sortOrder: 0
        )
        let second = FocusTask(
            title: "Second",
            createdAt: Date(timeIntervalSince1970: 10),
            sortOrder: 1
        )
        let completed = FocusTask(title: "Completed", sortOrder: -1)
        completed.complete(at: Date(timeIntervalSince1970: 30))

        let result = TaskListPresentation.visibleTasks(
            from: [completed, second, first],
            filter: .all
        )

        #expect(result.map(\.title) == ["First", "Second", "Completed"])
    }

    @Test("Archived tasks are recoverable and sorted consistently")
    func sortsArchivedTasks() {
        let active = FocusTask(title: "Active", sortOrder: -1)
        let second = FocusTask(
            title: "Second archived",
            createdAt: Date(timeIntervalSince1970: 20),
            sortOrder: 1,
            isArchived: true
        )
        let first = FocusTask(
            title: "First archived",
            createdAt: Date(timeIntervalSince1970: 10),
            sortOrder: 0,
            isArchived: true
        )

        let result = TaskListPresentation.archivedTasks(
            from: [active, second, first]
        )

        #expect(result.map(\.title) == ["First archived", "Second archived"])
    }
}
