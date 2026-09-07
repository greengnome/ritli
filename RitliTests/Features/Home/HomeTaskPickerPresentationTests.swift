import Foundation
import Testing
@testable import Ritli

struct HomeTaskPickerPresentationTests {
    @Test("Only active non-archived tasks are selectable from Home")
    func filtersUnavailableTasks() {
        let active = FocusTask(title: "Active")
        let completed = FocusTask(title: "Completed")
        completed.complete(at: .now)
        let archived = FocusTask(title: "Archived", isArchived: true)

        let result = HomeTaskPickerPresentation.selectableTasks(
            from: [completed, archived, active]
        )

        #expect(result.map(\.title) == ["Active"])
    }

    @Test("Selectable tasks preserve their explicit order")
    func sortsTasks() {
        let second = FocusTask(
            title: "Second",
            createdAt: Date(timeIntervalSince1970: 10),
            sortOrder: 1
        )
        let first = FocusTask(
            title: "First",
            createdAt: Date(timeIntervalSince1970: 20),
            sortOrder: 0
        )

        let result = HomeTaskPickerPresentation.selectableTasks(from: [second, first])

        #expect(result.map(\.title) == ["First", "Second"])
    }
}
