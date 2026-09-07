import SwiftData

@MainActor
enum FocusHistoryCleaner {
    @discardableResult
    static func clearRecordedSessions(in context: ModelContext) throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let recordedSessions = sessions.filter { $0.state.isTerminal }

        for session in recordedSessions {
            context.delete(session)
        }

        try context.save()
        return recordedSessions.count
    }
}
