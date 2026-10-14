import Foundation
import SwiftData

enum AppModelContainer {
    static let schema = Schema([
        FocusCategory.self,
        FocusTask.self,
        TimerRoutine.self,
        FocusSession.self,
        PomodoroSettings.self,
        PomodoroCycleState.self,
    ])

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        return try make(configuration: configuration)
    }

    static func make(configuration: ModelConfiguration) throws -> ModelContainer {
        if !configuration.isStoredInMemoryOnly {
            // A fresh app container may not have Application Support yet.
            // Prepare it before Core Data attempts to open the SQLite store.
            try FileManager.default.createDirectory(
                at: configuration.url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
