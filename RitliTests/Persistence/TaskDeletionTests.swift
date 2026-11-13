import Foundation
import SwiftData
import Testing
@testable import Ritli

/// Regression: deleting the task the timer remembers used to leave a
/// dangling reference that crashed on the next read, including at launch.
@MainActor
struct TaskDeletionTests {
    @Test("Deleting the remembered task clears it, now and after a relaunch")
    func deletingPreferredTaskClearsReference() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "TaskDeletionTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(
            schema: AppModelContainer.schema,
            url: directory.appending(path: "Ritli.store")
        )

        do {
            let container = try AppModelContainer.make(configuration: configuration)
            let context = container.mainContext
            let task = FocusTask(title: "Selected on Home")
            let cycle = PomodoroCycleState(preferredFocusTask: task)
            context.insert(task)
            context.insert(cycle)
            try context.save()

            task.isArchived = true
            try context.save()
            context.delete(task)
            try context.save()

            #expect(cycle.preferredFocusTask == nil)
        }

        let relaunched = try AppModelContainer.make(configuration: configuration)
        let context = relaunched.mainContext
        let cycle = try #require(context.fetch(FetchDescriptor<PomodoroCycleState>()).first)
        #expect(cycle.preferredFocusTask == nil)

        let engine = TimerEngine(
            store: SwiftDataTimerSessionStore(context: context),
            settings: PomodoroSettings(),
            cycleState: cycle
        )
        try engine.restore()
        #expect(engine.currentSession == nil)
    }
}
