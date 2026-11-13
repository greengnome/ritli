import Foundation
import SwiftData

@MainActor
protocol TimerSessionStore: AnyObject {
    func insert(_ session: FocusSession)
    func fetchActiveSession() throws -> FocusSession?
    func save() throws
    /// Discards unsaved changes after a failed save.
    func rollback()
}

@MainActor
final class SwiftDataTimerSessionStore: TimerSessionStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func insert(_ session: FocusSession) {
        context.insert(session)
    }

    func fetchActiveSession() throws -> FocusSession? {
        let running = SessionState.running.rawValue
        let paused = SessionState.paused.rawValue
        var descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate {
                $0.stateRawValue == running || $0.stateRawValue == paused
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    func save() throws {
        try context.save()
    }

    func rollback() {
        context.rollback()
    }
}
