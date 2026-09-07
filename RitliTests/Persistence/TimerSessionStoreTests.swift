import Foundation
import SwiftData
import Testing
@testable import Ritli

@MainActor
struct TimerSessionStoreTests {
    @Test("SwiftData store returns only the newest active session")
    func fetchesActiveSession() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let store = SwiftDataTimerSessionStore(context: context)
        let completed = FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: .now.addingTimeInterval(20),
            plannedDuration: 60
        )
        let running = FocusSession(
            kind: .focus,
            startedAt: .now,
            plannedDuration: 60,
            endDate: .now.addingTimeInterval(60)
        )
        store.insert(running)
        store.insert(completed)
        try store.save()

        #expect(try store.fetchActiveSession() === running)
    }
}
