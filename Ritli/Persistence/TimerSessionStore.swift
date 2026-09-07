import Foundation
import SwiftData

@MainActor
protocol TimerSessionStore: AnyObject {
    func insert(_ session: FocusSession)
    func fetchActiveSession() throws -> FocusSession?
    func save() throws
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
        var descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 2

        return try context.fetch(descriptor).first {
            $0.state == .running || $0.state == .paused
        }
    }

    func save() throws {
        try context.save()
    }
}
