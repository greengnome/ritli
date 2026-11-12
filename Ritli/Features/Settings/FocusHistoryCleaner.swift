import SwiftData

@MainActor
enum FocusHistoryCleaner {
    /// Deletes finished sessions. Running or paused sessions stay, and each
    /// task keeps its progress, as the confirmation dialog promises.
    @discardableResult
    static func clearRecordedSessions(in context: ModelContext) throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let recordedSessions = sessions.filter { $0.state.isTerminal }

        for session in recordedSessions {
            if session.kind == .focus, session.state == .completed {
                session.task?.clearedPomodoroCount += 1
            }
            context.delete(session)
        }

        try context.save()
        return recordedSessions.count
    }
}
