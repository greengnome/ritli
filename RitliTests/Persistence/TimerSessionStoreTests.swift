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

    @Test("An active session is found even behind newer finished ones")
    func findsActiveSessionBehindNewerHistory() throws {
        // A clock moved backwards can leave newer-dated records ahead of
        // the active session; the store must not stop at the first few.
        let container = try AppModelContainer.make(inMemory: true)
        let store = SwiftDataTimerSessionStore(context: container.mainContext)
        let base = Date(timeIntervalSince1970: 50_000)
        let paused = FocusSession(
            kind: .focus,
            state: .paused,
            startedAt: base,
            plannedDuration: 60,
            pausedRemainingTime: 30
        )
        store.insert(paused)
        for offset in 1...3 {
            store.insert(FocusSession(
                kind: .focus,
                state: .completed,
                startedAt: base.addingTimeInterval(Double(offset) * 3_600),
                plannedDuration: 60
            ))
        }
        try store.save()

        #expect(try store.fetchActiveSession() === paused)
    }
}
