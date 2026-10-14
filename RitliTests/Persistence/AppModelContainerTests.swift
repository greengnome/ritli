import Foundation
import SwiftData
import Testing
@testable import Ritli

@MainActor
struct AppModelContainerTests {
    @Test("A fresh disk store creates its parent directories and survives reopening")
    func createsDiskStoreDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("Library/Application Support/default.store")
        let configuration = ModelConfiguration(schema: AppModelContainer.schema, url: url)
        #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))

        try autoreleasepool {
            let container = try AppModelContainer.make(configuration: configuration)
            container.mainContext.insert(FocusCategory(name: "Persisted", colorToken: "purple"))
            try container.mainContext.save()
        }

        #expect(FileManager.default.fileExists(atPath: url.path))
        let reopened = try AppModelContainer.make(configuration: configuration)
        let categories = try reopened.mainContext.fetch(FetchDescriptor<FocusCategory>())
        #expect(categories.map(\.name) == ["Persisted"])
    }

    @Test("An invalid disk store parent still reports an error")
    func rejectsInvalidDiskStoreDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let blocker = root.appendingPathComponent("not-a-directory")
        try Data("occupied".utf8).write(to: blocker)
        let configuration = ModelConfiguration(
            schema: AppModelContainer.schema,
            url: blocker.appendingPathComponent("default.store")
        )

        #expect(throws: CocoaError.self) {
            try AppModelContainer.make(configuration: configuration)
        }
        #expect(try Data(contentsOf: blocker) == Data("occupied".utf8))
    }

    @Test("All domain models persist in the configured schema")
    func persistsDomainGraph() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let category = FocusCategory(name: "Study", colorToken: "purple")
        let routine = TimerRoutine(name: "Deep work", focusDuration: 3_000)
        let task = FocusTask(
            title: "Learn Spanish",
            category: category,
            timerRoutine: routine
        )
        let session = FocusSession(
            kind: .focus,
            state: .completed,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task
        )

        context.insert(category)
        context.insert(task)
        context.insert(routine)
        context.insert(session)
        context.insert(PomodoroSettings())
        let snapshot = TimerRoutineSnapshot(
            focusDuration: 3_000,
            shortBreakDuration: 600,
            longBreakDuration: 1_200,
            longBreakEvery: 3,
            autoStartBreaks: true,
            autoStartFocus: false
        )
        context.insert(
            PomodoroCycleState(
                preferredFocusTask: task,
                routineSnapshot: snapshot
            )
        )
        try context.save()

        #expect(try context.fetch(FetchDescriptor<FocusCategory>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusTask>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<TimerRoutine>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PomodoroSettings>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PomodoroCycleState>()).count == 1)
        #expect(
            try context.fetch(FetchDescriptor<PomodoroCycleState>())
                .first?.preferredFocusTask === task
        )
        #expect(
            try context.fetch(FetchDescriptor<PomodoroCycleState>())
                .first?.routineSnapshot == snapshot
        )
        #expect(
            try context.fetch(FetchDescriptor<FocusTask>())
                .first?.timerRoutine === routine
        )
    }
}
