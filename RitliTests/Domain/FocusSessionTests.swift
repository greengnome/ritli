import Foundation
import Testing
@testable import Ritli

struct FocusSessionTests {
    @Test("A session snapshots its resolved category")
    func snapshotsCategory() {
        let category = FocusCategory(name: "Work", colorToken: "orange")
        let task = FocusTask(title: "Roadmap", category: category)
        let session = FocusSession(
            kind: .focus,
            plannedDuration: 1_500,
            task: task,
            timeZone: TimeZone(identifier: "UTC")!
        )

        #expect(session.category === category)
        #expect(session.categoryNameSnapshot == "Work")
        #expect(session.categoryColorTokenSnapshot == "orange")
    }

}
